///////////////////////////////////////////////////////////////////////////////
///
/// Uses cmStringUtil::format function to output strings. This allows
/// for fancy printf-like formatting. See cmStringUtil::format for
/// docs on options.
///
///    To convert old %s0..%s9 to new format use {0}..{9}
///    Old vsMsgUtilXXXX calls must convert SEString to cmStringUtf8 which
///    causes slight performance hit but unless you're fetching an error
///    message millions of times, this should no matter.
///
///    For new error messages which calls cmMsg use
//         {0}.. {9} for pointers to cmStringUtf8

#pragma once

#error "Can't include vsmsgdefs.h. Must include vsmsgdefs_*.h"


#ifndef VSMSGDEFS_FIO_H
#define VSMSGDEFS_FIO_H
enum VSMSGDEFS_FIO {
    // File not found
    FILE_NOT_FOUND_RC = -2,
    // Path not found
    PATH_NOT_FOUND_RC = -3,
    // Too many open files
    TOO_MANY_OPEN_FILES_RC = -4,
    // Access denied
    ACCESS_DENIED_RC = -5,
    // Memory control blocks destroyed.  Save files and reboot.
    MEMORY_CONTROL_BLOCKS_RC = -7,
    // Insufficient memory
    INSUFFICIENT_MEMORY_RC = -8,
    // File exceeds size limit
    FILE_TOO_LARGE_RC = -9,
    // Invalid drive
    INVALID_DRIVE_RC = -15,
    // No more files
    NO_MORE_FILES_RC = -18,
    // Disk is write-protected
    DISK_IS_WRITE_PROTECTED_RC = -19,
    // Unknown unit
    UNKNOWN_UNIT_RC = -20,
    // Drive not ready
    DRIVE_NOT_READY_RC = -21,
    // Bad device command
    BAD_DEVICE_COMMAND_RC = -22,
    // Data error (CRC)
    DATA_ERROR_RC = -23,
    // Bad request structure length
    BAD_REQUEST_STRUCTURE_LENGTH_RC = -24,
    // Seek error
    SEEK_ERROR_RC = -25,
    // Unknown media type
    UNKNOWN_MEDIA_TYPE_RC = -26,
    // Sector not found
    SECTOR_NOT_FOUND_RC = -27,
    // Printer out of paper
    PRINTER_OUT_OF_PAPER_RC = -28,
    // Write fault
    WRITE_FAULT_RC = -29,
    // Read fault
    READ_FAULT_RC = -30,
    // General failure
    GENERAL_FAILURE_RC = -31,
    // Error opening file
    ERROR_OPENING_FILE_RC = -32,
    // Error reading file
    ERROR_READING_FILE_RC = -33,
    // Error writing file
    ERROR_WRITING_FILE_RC = -34,
    // Error closing file
    ERROR_CLOSING_FILE_RC = -35,
    // Insufficient disk space
    INSUFFICIENT_DISK_SPACE_RC = -36,
    // Program can not be run in OS/2 mode
    PROGRAM_CAN_NOT_BE_RUN_IN_OS2_RC = -37,
    // Error creating directory entry
    ERROR_CREATING_DIRECTORY_RC = -38,
    // Session parent already exists
    SESSION_PARENT_EXISTS_RC = -39,
    // Unable to open error code temp file.
    UNABLE_TO_OPEN_ERROR_CODE_TEMP_FILE_RC = -43,
    // Unable to open PIF temp file.
    UNABLE_TO_OPEN_PIF_TEMP_FILE_RC = -44,
    // Bad error code temp file
    BAD_ERROR_CODE_TEMP_FILE_RC = -45,
    // Invalid executable format
    INVALID_EXECUTABLE_FORMAT_RC = -46,
    // System failed to execute program
    SYSTEM_FAILED_TO_EXECUTE_PROGRAM_RC = -47,
    // Program WDOSRC.EXE not found.
    WDOSRC_FILE_NOT_FOUND_RC = -48,
    // Unable to create timer
    FIOERROR_CREATING_TIMER_RC = -49,
    // Unable to create timer
    FIOBREAK_KEY_PRESSED_RC = -50,
    // Program SLKSHELL.EXE not found.
    SLKSHELL_FILE_NOT_FOUND_RC = -51,
    // Invalid argument
    FIOINVALID_ARGUMENT_RC = -52,
    // End of file reached
    EOF_RC = -53,
    // File '{1}' not found
    ARGFILE_NOT_FOUND_RC = -54,
    // Access denied to file {1}
    ARGACCESS_DENIED_RC = -55,
    // Path not found for file {1}
    ARGPATH_NOT_FOUND_RC = -56,
    // Unable to open file {1}
    ARGUNABLE_TO_OPEN_FILE_RC = -57,
    // Member in use
    MEMBER_IN_USE_RC = -58,
    // Data set in use
    DATASET_IN_USE_RC = -59,
    // Data set or member in use
    DATASET_OR_MEMBER_IN_USE_RC = -60,
    // Volume out of space
    VOLUME_OUT_OF_SPACE_RC = -61,
    // Data set out of extent
    DATASET_OUT_OF_EXTENT_RC = -62,
    // PDS directory out of space
    PDS_DIR_OUT_OF_SPACE_RC = -63,
    // Data set I/O error
    DATASET_IO_RC = -64,
    // Unsupported data set type
    UNSUPPORTED_DATASET_TYPE_RC = -65,
    // Data set not PDS
    DATASET_NOT_PDS_RC = -66,
    // PDS member not found
    PDS_MEMBER_NOT_FOUND_RC = -67,
    // No more available DD name
    NO_MORE_DDNAME_RC = -68,
    // Unable to allocate DD name to data set
    UNABLE_TO_ALLOCATE_DDNAME_TO_DATASET_RC = -69,
    // Data set not sequential
    DATASET_NOT_SEQUENTIAL_RC = -70,
    // Unsupported data set operation
    UNSUPPORTED_DATASET_OPERATION_RC = -71,
    // Invalid data set name
    INVALID_DATASET_NAME_RC = -72,
    // Invalid PDS member name
    INVALID_PDS_MEMBER_NAME_RC = -73,
    // Insufficient access to data set
    INSUFFICIENT_ACCESS_TO_DATASET_RC = -74,
    // Unable to update PDS member directory
    UNABLE_TO_UPDATE_PDS_MEMBER_DIRECTORY_RC = -75,
    // Invalid data set password
    INVALID_DATASET_PASSWORD_RC = -76,
    // Data set not found
    DATASET_NOT_FOUND_RC = -77,
    // Cannot access internal reader
    CANT_ACCESS_INTERNAL_READER_RC = -78,
    // Cannot write to syslog
    CANT_WRITE_TO_SYSLOG_RC = -79,
    // Cannot load assembler modules
    CANT_LOAD_ASSEMBLER_MODULES_RC = -80,
    // Cannot query system data set listing
    CANT_QUERY_SYSTEM_DATASET_LISTING_RC = -81,
    // Insufficient spill disk space. Please inform the system programmers and check your SlickEdit log /tmp/vslog.YourUSERID for more information.
    INSUFFICIENT_SPILL_DISK_SPACE_RC = -82,
    // Insufficient user log disk space. Please inform the system programmers and check your SlickEdit log /tmp/vslog.YourUSERID for more information.
    INSUFFICIENT_LOG_DISK_SPACE_RC = -83,
    // User log /tmp/vslog.YourUSERID too large. All further logging suppressed.
    USER_LOG_TOO_LARGE_RC = -84,
    // Bad URL
    URL_BAD_RC = -85,
    // URL protocol not supported
    URL_PROTO_NOT_SUPPORTED_RC = -86,
    // Error reading response or response invalid
    URL_ERROR_READING_RESPONSE_RC = -87,
    // URL status condition - {1}
    URL_STATUS_RC = -88,
    // URL moved
    URL_MOVED_RC = -89,
    // URL response not supported - {1}
    URL_RESPONSE_NOT_SUPPORTED_RC = -90,
    // Invalid argument
    VSRC_INVALID_ARGUMENT = -91,
    // Buffer overflow
    BUFFER_OVERFLOW_RC = -92,
    // Error creating or setting registry value {1}
    ERROR_CREATING_REGISTRY_VALUE_RC = -93,
    // Error creating registry key {1}
    ERROR_CREATING_REGISTRY_KEY_RC = -94,
    // Cannot open FIFO file
    CANNOT_OPEN_FIFO_FILE_RC = -95,
    // URL redirect to HTTPS not supported
    URL_MOVED_HTTPS_NOT_SUPPORTED_RC = -96,
    // Move destination already exists
    MOVE_DESTINATION_ALREADY_EXISTS_RC= -97
};
#endif

#ifndef VSMSGDEFS_SOCK_H
#define VSMSGDEFS_SOCK_H
enum VSMSGDEFS_SOCK {
    // General socket error
    SOCK_GENERAL_ERROR_RC = -100,
    // Socks system failed to initialize
    SOCK_INIT_FAILED_RC = -101,
    // Socks system not initialized
    SOCK_NOT_INIT_RC = -102,
    // Bad host address or host not found
    SOCK_BAD_HOST_RC = -103,
    // No more sockets available
    SOCK_NO_MORE_SOCKETS_RC = -104,
    // Socket timed out
    SOCK_TIMED_OUT_RC = -105,
    // Bad port
    SOCK_BAD_PORT_RC = -106,
    // Bad socket
    SOCK_BAD_SOCKET_RC = -107,
    // Socket not connected
    SOCK_SOCKET_NOT_CONNECTED_RC = -108,
    // Socket would have blocked
    SOCK_WOULD_BLOCK_RC = -109,
    // Network down
    SOCK_NET_DOWN_RC = -110,
    // Not enough memory
    SOCK_NOT_ENOUGH_MEMORY_RC = -111,
    // Argument not large enough
    SOCK_SIZE_ERROR_RC = -112,
    // No more data
    SOCK_NO_MORE_DATA_RC = -113,
    // Address not available
    SOCK_ADDR_NOT_AVAILABLE_RC = -114,
    // Socket not listening
    SOCK_NOT_LISTENING_RC = -115,
    // No pending connections
    SOCK_NO_CONN_PENDING_RC = -116,
    // Connection aborted
    SOCK_CONN_ABORTED_RC = -117,
    // Connection reset
    SOCK_CONN_RESET_RC = -118,
    // Socket shut down
    SOCK_SHUTDOWN_RC = -119,
    // Connection closed
    SOCK_CONNECTION_CLOSED_RC = -120,
    // No protocol available
    SOCK_NO_PROTOCOL_RC = -121,
    // Connection refused
    SOCK_CONN_REFUSED_RC = -122,
    // Nonauthoritative host not found
    SOCK_TRY_AGAIN_RC = -123,
    // Host not found
    SOCK_NO_RECOVERY_RC = -124,
    // Socket or address in use
    SOCK_IN_USE_RC = -125,
};
#endif

#ifndef VSMSGDEFS_VSPROXY_H
#define VSMSGDEFS_VSPROXY_H
enum VSMSGDEFS_VSPROXY {
    // Command line too long
    VSPROXY_CMDLINE_TOO_LONG_RC = -150,
    // Broken pipe
    VSPROXY_BROKEN_PIPE_RC = -151,
    // Bad pipe
    VSPROXY_BAD_PIPE_RC = -152,
    // Invalid handle
    VSPROXY_INVALID_HANDLE_RC = -153,
    // Invalid command
    VSPROXY_INVALID_COMMAND_RC = -154,
    // Not enough arguments
    VSPROXY_NOT_ENOUGH_ARGUMENTS_RC = -155,
    // Already transferring data
    VSPROXY_ALREADY_TRANSFERRING_DATA_RC = -156,
    // Bad file handle
    VSPROXY_BAD_FILE_HANDLE_RC = -157,
    // No transfer source/destination specified
    VSPROXY_NO_TRANSFER_SOURCEDEST_RC = -158,
    // Not transferring data
    VSPROXY_NOT_TRANSFERRING_DATA_RC = -159,
    // Still transferring data
    VSPROXY_STILL_TRANSFERRING_DATA_RC = -160,
};
#endif

#ifndef VSMSGDEFS_CFORMAT_H
#define VSMSGDEFS_CFORMAT_H
enum VSMSGDEFS_CFORMAT {
    // General error
    CFERROR_GENERAL_ERROR_RC = -200,
    // Unexpected end-of-file
    CFERROR_EOF_UNEXPECTED_RC = -201,
    // Unexpected symbol
    CFERROR_SYMBOL_UNEXPECTED_RC = -202,
    // Right parenthesis expected
    CFERROR_RIGHTPAREN_EXPECTED_RC = -203,
    // Right brace expected
    CFERROR_RIGHTBRACE_EXPECTED_RC = -204,
    // Right bracket expected
    CFERROR_RIGHTBRACKET_EXPECTED_RC = -205,
    // Left parenthesis expected
    CFERROR_LEFTPAREN_EXPECTED_RC = -206,
    // Left brace expected
    CFERROR_LEFTBRACE_EXPECTED_RC = -207,
    // Left bracket expected
    CFERROR_LEFTBRACKET_EXPECTED_RC = -208,
    // Unexpected right parenthesis
    CFERROR_RIGHTPAREN_UNEXPECTED_RC = -209,
    // Unexpected right brace, possible missing ;
    CFERROR_RIGHTBRACE_UNEXPECTED_RC = -210,
    // Unexpected right bracket
    CFERROR_RIGHTBRACKET_UNEXPECTED_RC = -211,
    // Unexpected left parenthesis
    CFERROR_LEFTPAREN_UNEXPECTED_RC = -212,
    // Unexpected left brace
    CFERROR_LEFTBRACE_UNEXPECTED_RC = -213,
    // Unexpected left bracket
    CFERROR_LEFTBRACKET_UNEXPECTED_RC = -214,
    // Unexpected case
    CFERROR_CASE_UNEXPECTED_RC = -215,
    // Expected colon
    CFERROR_COLON_EXPECTED_RC = -216,
    // Expected semicolon
    CFERROR_SEMI_EXPECTED_RC = -217,
    // Unexpected preprocessor
    CFERROR_PP_UNEXPECTED_RC = -218,
    // Expected while
    CFERROR_WHILE_EXPECTED_RC = -219,
    // Unexpected else
    CFERROR_ELSE_UNEXPECTED_RC = -220,
    // Error in template
    CFERROR_ERROR_IN_TEMPLATE_RC = -221,
    // Unexpected endsubmenu
    CFERROR_ENDSUBMENU_UNEXPECTED_RC = -222,
    // Unexpected submenu
    CFERROR_SUBMENU_UNEXPECTED_RC = -223,
    // Unexpected _menu
    CFERROR_MENU_UNEXPECTED_RC = -224,
    // Unexpected catch
    CFERROR_CATCH_UNEXPECTED_RC = -225,
    // Unexpected finally
    CFERROR_FINALLY_UNEXPECTED_RC = -226,
    // Unhandled syntax
    CFERROR_UNHANDLED_SYNTAX_RC = -227,
};
#endif

#ifndef VSMSGDEFS_VSSETLN_H
#define VSMSGDEFS_VSSETLN_H
enum VSMSGDEFS_VSSETLN {
    // Unable to open file '{1}'.  Make sure this executable is not already running.
    VSSETLN_UNABLE_TO_OPEN_FILE_RC = -300,
    // Executable file '{1}' not found
    VSSETLN_EXECUTABLE_FILE_NOT_FOUND_RC = -301,
    // Error reading file '{1}'
    VSSETLN_ERROR_READING_FILE_RC = -302,
    // Could not find version marker in file '{1}'
    VSSETLN_COULD_NOT_FIND_MARKER_RC = -303,
    // Bad version number in file '{1}'
    VSSETLN_BAD_VERSION_NUMBER_RC = -304,
    // Could not find serial marker in file '{1}'
    VSSETLN_SERIAL_MARKER_NOT_FOUND_RC = -305,
    // Error writing to file '{1}'.  Check disk space.
    VSSETLN_ERROR_WRITING_TO_FILE_RC = -306,
    // License '{1}' successfully stored
    VSSETLN_LICENSE_STORED2_RC = -307,
    // License successfully stored.
    VSSETLN_LICENSE_STORED_RC = -308,
    // Warning - Unable to copy vs.exe to temp file.  Could be out of disk space.
    VSSETLN_COPY_FAILED_RC = -309,
    // Warning - Unable to delete vs.exe
    VSSETLN_DELETE_FAILED_RC = -310,
    // Warning - Unable to move temp file to vs.exe.
    VSSETLN_MOVE_FAILED_RC = -311,
    // Invalid key
    VSSETLN_INVALID_KEY_RC = -312,
    // Please enter full path and executable.
    VSSETLN_ENTER_FULL_PATH_RC = -313,
    // Must give the full path and executable name
    VSSETLN_MUST_GIVE_PATH_AND_NAME_RC = -314,
    // Invalid key - prefix mismatch
    VSSETLN_PREFIX_MISMATCH_RC = -315,
    // Invalid key - version mismatch
    VSSETLN_VERSION_MISMATCH_RC = -316,
    // Location of Executable
    VSSETLN_LOCATION_OF_EXE_RC = -317,
    // 
    // vssetln Version 12.0
    // 
    // This program is used to patch the SlickEdit executable with
    // a license code.
    // 
    // Usage:
    // 	vssetln [-r] executable license-key
    // 
    // 	-r	Replace license.
    // 	executable	Name of program executable.
    // 	license-key	License-key code to patch into executable.
    // 
    // Example:
    // 
    // 	vssetln vs 0123456789-0000-AAA012345-BBB
    // 
    // 
    VSSETLN_HELP_UNIX_RC = -318,
    // Unable to execute {1}.  Could be out of memory.
    VSSETLN_UNABLE_TO_EXECUTE_RC = -319,
    // Could not find license marker in file '{1}'.
    VSSETLN_LICENSE_MARKER_NOT_FOUND_RC = -320,
    // Could not find package marker in file '{1}'.
    VSSETLN_PACKS_MARKER_NOT_FOUND_RC = -321,
    // SlickEdit Set License
    VSSETLN_MESSAGEBOX_TITLE_RC = -322,
    // Invalid key ({1})
    VSSETLN_INVALID_KEY2_RC = -323,
    // Cannot replace license with this key.  Invoke 'vssetlnw.exe' without the -r switch if you are trying to add a package to your license.
    VSSETLNW_REPLACE_NOT_VALID_RC = -324,
    // Cannot replace license with this key.  Invoke 'vssetln' without the -r switch if you are trying to add a package to your license.
    VSSETLN_REPLACE_NOT_VALID_RC = -325,
    // Unable to update the license file '{1}'.  This can happen when the license file is read only.  The system administrator must add the following package sections manually.  Read the "License Manager" section of the manual for more information on adding packages to the license file.
    VSSETLN_UNABLE_TO_UPDATE_LICENSE_FILE_RC = -326,
    // Unable to open the license file '{1}'.
    VSSETLN_UNABLE_TO_OPEN_LICENSE_FILE_RC = -327,
    // The serial #{1} does not match the license for package <{2}>.
    // 
    // This can happen when you attempt to install a licensed package for a serial number that is different from the one currently licensed.
    // 
    // or
    // 
    // You are attempting to install a non-STD package key for an unlicensed executable.  You must first install your original key before applying the new key.
    VSSETLN_SERIAL_AND_LICENSE_MISMATCH_RC = -328,
    // Cannot set license on a trial.
    VSSETLN_CANNOT_UPDATE_TRIAL_RC = -329,
    // Executable patched {0} times
    VSSETLN_NUMBER_OF_TIMES_PATCHED = -330,
};
#endif

#ifndef VSMSGDEFS_VSUPDATE_H
#define VSMSGDEFS_VSUPDATE_H
enum VSMSGDEFS_VSUPDATE {
    // Serial number and license information successfully transferred
    VSUPDATE_LICENSE_TRANSFERRED_RC = -350,
    // 
    // vsupdate Version 12.0
    // 
    // This program is used to copy the serial number and license information from one SlickEdit executable to another.
    // 
    // Usage:
    // 	vsupdate old-exe-name new-exe-name
    // 
    // 	old-exe-name	Name of original executable to take license information from.
    // 	new-exe-name	Name of new executable to transfer license information to.
    VSUPDATE_HELP_RC = -351,
    // Invalid serial number
    VSUPDATE_INVALID_SERIAL_NUMBER_RC = -352,
    // Version 12.0
    // 
    // This program is used to copy the serial number and license information from one SlickEdit executable to another.
    // 
    // Usage:
    // 	vsupdatw old-exe-name new-exe-name
    // 
    // 	old-exe-name	Name of original executable to take license information from.
    // 	new-exe-name	Name of new executable to transfer license information to.
    VSUPDATE_HELP_WIN_RC = -353,
    // Invalid or missing license
    VSUPDATE_INVALID_LICENSE_RC = -354,
    // Invalid or missing packages
    VSUPDATE_INVALID_PACKS_RC = -355,
    // Hot fix file is not for this machine architecture
    VSUPDATE_INCORRECT_ARCHITECTURE_RC = -356,
    // Hot fix contains DLLs that are for Windows platforms only
    VSUPDATE_DLL_ONLY_FOR_WINDOWS_RC = -357,
};
#endif

#ifndef VSMSGDEFS_CDINST_H
#define VSMSGDEFS_CDINST_H
enum VSMSGDEFS_CDINST {
    // Installation failed
    // 
    // Unable to execute {1}.  Could be out of memory.
    CDINST_UNABLE_TO_EXECUTE_RC = -400,
    // Installation failed
    // 
    // Unable to create directory {1}
    CDINST_FAILED_TO_CREATE_DIR_RC = -401,
    // Installation failed while decompressing {1}.
    // 
    // {2}
    CDINST_FAILED_DECOMPRESSING_RC = -402,
    // Copying {1} to {2}
    CDINST_COPYING_FROM_TO_RC = -403,
    // Installation failed.
    // 
    // Error setting date/time of file '{1}'
    CDINST_ERROR_SETTING_DATE_TIME_RC = -404,
    // Installation failed.
    // 
    // File '{1}' not found
    CDINST_FILE_NOT_FOUND_RC = -405,
    // Installation failed.
    // 
    // Access denied writing to '{1}'. Make sure '{1}' is not currently running.
    CDINST_ACCESS_DENIED_RC = -406,
    // Installation failed.
    // 
    // Path not found {1}
    CDINST_PATH_NOT_FOUND_RC = -407,
    // Installation failed.
    // 
    // Insufficient disk space
    CDINST_INSUFFICIENT_DISK_SPACE_RC = -408,
    // Installation failed.
    // 
    // Not enough memory
    CDINST_NOT_ENOUGH_MEMORY_RC = -409,
    // Installation failed while processing {1}
    // 
    // error code {2}
    CDINST_ERROR_CODE_RC = -410,
    // Please specify directory
    CDINST_PLEASE_SPECIFY_DIRECTORY_RC = -411,
    // Backup directory {1} already exists.
    // 
    // Replace files?
    CDINST_BACKUP_DIRECTORY_EXISTS_RC = -412,
    // Cannot backup to installation directory.
    CDINST_CANT_BACKUP_TO_INSTALL_DIR_RC = -413,
    // Please specify destination directory
    CDINST_PLEASE_SPECIFY_DEST_DIR_RC = -414,
    // Directory {1} does not exist
    // 
    // Create it?
    CDINST_MAYBE_CREATE_DIR_RC = -415,
    // Failed to create directory
    // 
    // {1}
    CDINST_FAILED_TO_CREATE_DIR2_RC = -416,
    // Installation failed
    // 
    // Unable to write serial#/license.
    CDINST_UNABLE_TO_WRITE_SERIAL_RC = -417,
    // Installation failed
    // 
    // Unable to read serial#.
    CDINST_UNABLE_TO_READ_SERIAL_RC = -418,
    // Installation failed
    // 
    // Unable to open executable in order to patch in serial number.
    CDINST_UNABLE_TO_PATCH_SERIAL_RC = -419,
    // Installation failed
    // 
    // Unable to find serial#.
    CDINST_UNABLE_TO_FIND_SERIAL_RC = -420,
    // Installation failed
    // 
    // Unable to copy vs.exe to temp file.  Could be out of disk space.
    CDINST_UNABLE_TO_COPY_VSE_RC = -421,
    // Installation failed
    // 
    // Unable to delete vs.exe.
    CDINST_UNABLE_TO_DELETE_VSE_RC = -422,
    // Installation failed
    // 
    // Unable to move temp file to vs.exe.
    CDINST_UNABLE_TO_MOVE_VSE_RC = -423,
    // Select a directory
    CDINST_SELECT_A_DIRECTORY_RC = -424,
    // This installation requires {1} megabytes of disk space.  An additional {2} megabytes of disk space is required on this drive due to fragmentation.
    CDINST_INSUFFICIENT_DISK_SPACE2_RC = -425,
    // You have enough disk space for this installation,  but you do not have enough disk space to fully support Microsoft Visual C++ and Java.  An additional {1} megabytes of disk space are needed for Visual C++ and {2} megabytes for Java.  An installation with support for Microsoft Visual C++ and Java requires {3} megabytes of disk space ({4} megabytes was added to account for disk fragmentation).
    // 
    // Continue?
    CDINST_INSUFFICIENT_DISK_SPACE3_RC = -426,
    // This installation requires {1} megabytes of disk space.  An additional {2} megabytes of disk space is required on this drive due to fragmentation.  If you are installing over an existing installation, you may have enough disk space.
    // 
    // Continue?
    CDINST_INSUFFICIENT_DISK_SPACE4_RC = -427,
    // {1} already exists.
    // 
    // Continue?
    CDINST_CHOSEN_DIRECTORY_RC = -428,
    // Abort installation?
    CDINST_ABORT_RC = -429,
    // SlickEdit Install
    CDINST_MESSAGEBOX_TITLE_RC = -430,
    // Error opening license file
    CDINST_ERROR_OPENING_LICENSE_FILE_RC = -431,
    // {1} does not contain an upgradable version of SlickEdit
    CDINST_UPGRADEABLE_VSE_NOT_FOUND_RC = -432,
    // The v{1} upgrade installation is only valid for upgrading the following versions: {2}. Please contact sales at SlickEdit Inc. to obtain a v{1} installation key and directions for full installation.
    CDINST_BAD_UPGRADE_VERSION_RC = -433,
    // Cannot upgrade a multi-user license with the upgrade installer.  Please contact sales at SlickEdit Inc. to obtain an installation key and directions for full installation.
    CDINST_MULTIUSER_RC = -434,
    // Invalid serial number
    CDINST_INVALID_SERIAL_RC = -435,
    // A valid installation key code is required
    CDINST_KEY_REQUIRED_RC = -436,
    // {1} does not contain a valid distribution of SlickEdit
    CDINST_INVALID_DISTRIB_RC = -437,
    // Please re-insert installation media for SlickEdit {1}
    CDINST_INSERT_INSTALLATION_MEDIA_RC = -438,
    // Previous version of SlickEdit is invalid or corrupt
    CDINST_INVALID_PREV_INSTALL_RC = -439,
    // Invalid version of distribution and/or installation key code. The upgrade installation is only valid for the following versions: {1}. Please contact sales at SlickEdit Inc. to obtain an installation key and directions for full installation.
    CDINST_DISTRIB_KEY_MISMATCH_RC = -440,
    // Error copying file from {1} to {2}
    CDINST_ERROR_COPYING_FILE_RC = -441,
    // Installation of {1} was successful!
    CDINST_INSTALLATION_SUCCESSFUL_RC = -442,
    // Installation of {1} was successful!
    // 
    // Please start/restart WebSphere Studio or Eclipse to see the plug-in
    CDINST_ECLIPSE_INSTALLATION_SUCCESSFUL_RC = -443,
    // Please choose the installation type.
    // 
    // Choose Full Installation if you purchased the full v{1} product. Use the installation key found either on the back of your v{1} CD case if you purchased media, or in the email acknowledgement if you purchased online.
    // 
    // Choose Upgrade Installation if you purchased the v{1} upgrade product and are upgrading over a previous version. Valid versions to upgrade from are: {2}.
    CDINST_CHOOSE_INSTALL_TYPE_RC = -444,
    // A version {1} installation key is required.
    CDINST_WRONG_VERSION_RC = -445,
    // You must Accept the End User License Agreement to continue.
    CDINST_MUST_ACCEPT_EULA_RC = -446,
    // Please specify the {1} installation directory.  The directory will be created if it does not exist.
    CDINST_INSTALL_DESTINATION_CAPTION_RC = -447,
    // Installation of {1} was successful!
    CDINST_INSTALLATION_SUCCESSFUL2_RC = -448,
    // You have enough disk space for this installation,  but you may not have enough disk space to fully support C++ and Java.  An additional {1} megabytes of disk space are needed for C++ and {2} megabytes for Java.  An typical installation with support for C++ and Java runtimes requires {3} megabytes of disk space ({4} megabytes was added to account for disk fragmentation).
    // 
    // Continue?
    CDINST_INSUFFICIENT_DISK_SPACE5_RC = -449,
    // Invalid Eclipse product file '{1}'
    CDINST_INVALID_ECLIPSE_PRODUCT_FILE_RC = -450,
    // Eclipse product version {1} not supported. Supported versions are: {2}
    CDINST_ECLIPSE_PRODUCT_VERSION_NOT_SUPPORTED_RC = -451,
    // Warning: Eclipse product version is {1}. Supported versions are: {2}. Continue?
    CDINST_ECLIPSE_PRODUCT_VERSION_WARNING_RC = -452,
    // Example: c:\eclipse{1}\eclipse
    CDINST_ECLIPSE_LOCATION_EXAMPLE_RC = -453,
    // Platform mismatch.
    // 
    // Your installation key is intended for the following platform(s):
    // 	{1}
    // The platform you are currently on is:
    // 	{2}
    // 
    // Please contact SlickEdit Sales to obtain the correct installation key.
    CDINST_KEY_PLATFORM_MISMATCH_RC = -454,
    // Product mismatch.
    // 
    // Your installation key is intended for the following product(s):
    // 	{1}
    // The product you are currently installing is:
    // 	{2}
    // 
    // Please contact SlickEdit Sales to obtain the correct installation key.
    CDINST_KEY_PRODUCT_MISMATCH_RC = -455,
    // Warning: The Eclipse Product Id is not recognized. Continue?
    CDINST_ECLIPSE_PRODUCT_ID_MISMATCH_RC = -456,
    // Warning: The Eclipse Product Name is not recognized. Continue?
    CDINST_ECLIPSE_PRODUCT_NAME_MISMATCH_RC = -457,
};
#endif

#ifndef VSMSGDEFS_SUNPAK_H
#define VSMSGDEFS_SUNPAK_H
enum VSMSGDEFS_SUNPAK {
    // Incorrect version
    SUNPAK_INCORRECT_VERSION_RC = -480,
    // Invalid compressed file
    SUNPAK_INVALID_COMPRESS_FILE_RC = -481,
    // Error writing to file.  Could be out of disk space.
    SUNPAK_ERROR_WRITING_FILE_RC = -482,
    // Decompressing {1}
    SUNPAK_DECOMPRESSING_RC = -483,
    // Warning: time and date not set
    SUNPAK_DATE_NOT_SET_RC = -484,
    // Error setting date of file {1}
    SUNPAK_ERROR_DATE_NOT_SET_RC = -485,
    // Warning: time, date, permissions, owner, and group not preserved
    SUNPAK_DATE_NOT_SET_UNIX_RC = -486,
    // Error setting permissions of file {1}
    SUNPAK_ERROR_SETTING_PERMISSION_RC = -487,
    // Invalid option
    SUNPAK_INVALID_OPTION_RC = -488,
    // Error opening file "{1}".  Access denied.
    SUNPAK_OPEN_ACCESS_DENIED_RC = -489,
};
#endif

#ifndef VSMSGDEFS_KBIO_H
#define VSMSGDEFS_KBIO_H
enum VSMSGDEFS_KBIO {
    // Unable to initialize console
    UNABLE_TO_INIT_CONSOLE_RC = -500,
};
#endif

#ifndef VSMSGDEFS_VSUNINST_H
#define VSMSGDEFS_VSUNINST_H
enum VSMSGDEFS_VSUNINST {
    // {1} Uninstall Failed
    VSUNINST_TITLE_INSTALL_FAILED_RC = -550,
    // This uninstall program is not supported under Windows 3.1.
    // 
    // Use the File Manager to delete the SlickEdit files and directories.
    VSUNINST_WIN31_NOT_SUPPORTED_RC = -551,
    // Folder too short.  Not safe to run uninstall.
    // 
    // Folder {1}
    VSUNINST_FOLDER_TOO_SHORT_RC = -552,
    // Are you sure you want to uninstall {1}?
    // 
    // Folder {2}
    VSUNINST_ARE_YOU_SURE_RC = -553,
    // Uninstall completed
    VSUNINST_UNINSTALL_COMPLETED_RC = -554,
    // Uninstall completed.
    // 
    // Folder {1} contains files that are not part of the SlickEdit distribution package and which therefore were not deleted.
    VSUNINST_UNINSTALL_COMPLETED2_RC = -555,
    // Bad or missing argument "{1}".
    VSUNINST_BAD_ARGUMENT_RC = -556,
    // Unable to determine alternate temp directory
    VSUNINST_TEMP_DIRECTORY_NOT_FOUND_RC = -557,
    // Unable to create temp file {1}
    VSUNINST_UNABLE_TO_CREATE_TEMP_FILE_RC = -558,
    // Error writing to file '{1}'.  Check disk space.
    VSUNINST_ERROR_WRITING_TO_FILE_RC = -559,
    // Failed to execute {1} program
    VSUNINST_FAILED_TO_EXECUTE_RC = -560,
};
#endif

#ifndef VSMSGDEFS_LISTVTG_H
#define VSMSGDEFS_LISTVTG_H
enum VSMSGDEFS_LISTVTG {
    // Version 25.0
    // 
    // This program is used to list tags in a SlickEdit
    // tags database file (.vtg).
    // 
    //     Usage:
    //       listvtg [options] <tag file names> ...
    // 
    //     Where options are:
    //       -help      this message
    //       -langs     list languages
    //       -files     list files
    //       -classes   list classes
    //       -tags      list tags
    //       -refs      list references
    //       -sum       list summary
    //       -no-xxx    do not list xxx
    // 
    LISTVTG_VERSION_RC = -600,
    // Invalid file name: {1}
    // 
    LISTVTG_INVALID_FILENAME_RC = -601,
    // listvtg: database open error status = {1}
    // 
    LISTVTG_DBOPEN_ERROR_RC = -602,
    // listvtg: listing tag database file: {1}
    // 
    LISTVTG_LISTING_DBFILE_RC = -603,
    // [SEEK LOC]
    LISTVTG_SEEK_LOC_CAPTION_RC = -604,
    // File
    LISTVTG_FILE_CAPTION_RC = -605,
    // Modification Date
    LISTVTG_DATE_CAPTION_RC = -606,
    // Package-Class
    LISTVTG_PACKAGE_CLASS_CAPTION_RC = -607,
    // Parents
    LISTVTG_PARENTS_CAPTION_RC = -608,
    // Tag
    LISTVTG_TAG_RC = -609,
    // Class
    LISTVTG_CLASS_CAPTION_RC = -610,
    // Flags/Type
    LISTVTG_FLAGSTYPE_CAPTION_RC = -611,
    // File:Line
    LISTVTG_FILELINE_CAPTION_RC = -612,
    // listvtg: error closing database, {1}
    // 
    LISTVTG_ERROR_CLOSING_DATABASE_RC = -613,
    // listvtg: finished, {1} files, {2} classes, {3} tags in {4}
    // 
    LISTVTG_FINISHED_RC = -614,
    // Language ID
    LISTVTG_EXTN_CAPTION_RC = -615,
    // Occurrence
    LISTVTG_OCCURRENCE_RC = -616,
    // File:Seekpos
    LISTVTG_FILESEEKPOS_CAPTION_RC = -617,
};
#endif

#ifndef VSMSGDEFS_HFORMAT_H
#define VSMSGDEFS_HFORMAT_H
enum VSMSGDEFS_HFORMAT {
    // General error
    HFERROR_GENERAL_ERROR_RC = -700,
    // Unexpected end-of-file
    HFERROR_EOF_UNEXPECTED_RC = -701,
};
#endif

#ifndef VSMSGDEFS_SLICKT_H
#define VSMSGDEFS_SLICKT_H
enum VSMSGDEFS_SLICKT {
    // {1} {2} {3}:
    FILEPOS_RC = -1000,
    // 
    ST_VERSION_RC = -1001,
    //    vst [-e errfile] [-f offset] inputfile[.e] [outputfile[.ex]]
    // 
    // translates a .e macro file into a form executable by SlickEdit
    // 
    //    OPTIONS
    //       -dname=value   Declare constant
    //       -e errfile     Compile error is written to file errfile
    //       -f offset      Finds line and column of runtime error at offset
    //       -p PragmaOption [on|off]     Turn pragma option on or off
    //                      PragmaOption may be autodeclvars, autodeclctls, autodecl,
    //                      redeclvars, strictreturn, or strictellipse
    //       -q             Do not display standard messages
    //       -w             Wait for a key if an error occurs
    //       -t             Translate old macro.  Generates convert.tmp file
    STHELP_RC = -1002,
    // Identifier too long
    ID_TOO_LONG_RC = -1016,
    // Line too long
    LINE_TOO_LONG_RC = -1017,
    // Runtime error position found
    RUNTIME_ERROR_POS_FOUND_RC = -1018,
    // Illegal operator
    ILLEGAL_OPERATOR_RC = -1019,
    // Illegal character
    ILLEGAL_CHARACTER_RC = -1020,
    // DEFMAIN already defined
    DEFMAIN_ALREADY_DEFINED_RC = -1021,
    // Procedure already defined
    PROCEDURE_ALREADY_DEFINED_RC = -1022,
    // Number too large
    NUMBER_TOO_LARGE_RC = -1023,
    // String too long
    STRING_TOO_LONG_RC = -1024,
    // Code size too large
    OUT_OF_CODE_SPACE_RC = -1025,
    // Expression too complex
    EXP_TOO_COMPLEX_RC = -1026,
    // Internal error in POPS
    INTERNAL_ERROR_POPS_RC = -1027,
    // Unable to open error file
    UO_ERRFILE_RC = -1028,
    // Expecting '('
    EXPECTING_LEFT_PAREN_RC = -1029,
    // Expecting ')'
    EXPECTING_RIGHT_PAREN_RC = -1030,
    // Invalid number of parameters
    INVALID_NOFPARMS_RC = -1031,
    // Invalid expression
    INVALID_EXPRESSION_RC = -1032,
    // Expecting declaration
    EXPECTING_DEF_RC = -1033,
    // Expecting constant expression
    EXPECTING_CONSTANT_EXPRESSION_RC = -1034,
    // Expecting DO
    EXPECTING_DO_RC = -1035,
    // Expecting ENDWHILE to terminate WHILE
    EXPECTING_ENDWHILE_RC = -1036,
    // Expecting ENDLOOP to terminate LOOP
    EXPECTING_ENDLOOP_RC = -1037,
    // Expecting DO WHILE or DO FOREVER
    EXPECTING_DO_WHILE_RC = -1038,
    // Expecting END to DO loop
    EXPECTING_END_RC = -1039,
    // Expecting THEN
    EXPECTING_THEN_RC = -1040,
    // Expecting ENDIF to terminate IF statement
    EXPECTING_ENDIF_RC = -1041,
    // Expecting VALUE
    EXPECTING_VALUE_RC = -1042,
    // Expecting WITH
    EXPECTING_WITH_RC = -1043,
    // Column specification out of range
    COLUMN_SPEC_OUT_OF_RANGE_RC = -1044,
    // Number out of range or expecting number
    NUMBER_OUT_OF_RANGE_RC = -1045,
    // Expecting ';'
    EXPECTING_SEMICOLON_RC = -1046,
    // Expecting variable name
    EXPECTING_VARIABLE_NAME_RC = -1047,
    // continue may only be executed inside a loop
    INTERATE_USED_OUTSIDE_LOOP_RC = -1048,
    // Expecting quoted string
    EXPECTING_QUOTED_STRING_RC = -1049,
    // INCLUDES nested too deep
    INCLUDES_NESTED_TOO_DEEP_RC = -1050,
    // Invalid event name
    INVALID_EVENT_NAME_RC = -1051,
    // Expecting '='
    EXPECTING_EQUAL_RC = -1052,
    // This parameter must have a default value
    THIS_PARAMETER_MUST_HAVE_A_DEFAULT_VALUE_RC = -1053,
    // break may only be executed inside a loop or switch
    LEAVE_USED_OUTSIDE_LOOP_RC = -1054,
    // Expecting ENDFOR
    EXPECTING_ENDFOR_RC = -1055,
    // Expecting TO
    EXPECTING_TO_RC = -1056,
    // Out of symbol table space
    OUT_OF_SYMBOL_TABLE_SPACE_RC = -1057,
    // Identifier already defined as same or different type
    ID_ALREADY_DEFINED_RC = -1058,
    // Expecting procedure name - identifier not found - import may be required
    EXPECTING_PROCEDURE_NAME_RC = -1059,
    // Expecting an identifier
    EXPECTING_AN_IDENTIFIER_RC = -1060,
    // Invalid field name
    INVALID_FIELD_NAME_RC = -1061,
    // Expression not assignment compatible
    INVALID_ASSIGNMENT_RC = -1062,
    // Expecting ','
    EXPECTING_COMMA_RC = -1063,
    // Invalid argument
    STINVALID_ARGUMENT_RC = -1064,
    // String not terminated
    STRING_NOT_TERMINATED_RC = -1065,
    // Unable to read input file: {1}
    UR_INFILE_RC = -1066,
    // Unable to open input file: {1}
    UO_INFILE_RC = -1067,
    // Unable to create output file: {1}
    UC_OUTFILE_RC = -1068,
    // Unable to write output file: {1}
    UW_OUTFILE_RC = -1069,
    // Unable to open include file: {1}
    UO_INCLUDE_RC = -1070,
    // No source file specified
    NO_SOURCE_FILE_SPEC_RC = -1071,
    // Invalid option
    STINVALID_OPTION_RC = -1072,
    // Too many arguments
    STTOO_MANY_ARGUMENTS_RC = -1073,
    // Comment not terminated
    COMMENT_NOT_TERMINATED_RC = -1074,
    // Not enough memory
    STNOT_ENOUGH_MEMORY_RC = -1075,
    // Scope blocks nested too deep
    SCOPE_BLOCKS_NESTED_TOO_DEEP_RC = -1076,
    // More than {1} local variables
    TOO_MANY_LOCALS_RC = -1077,
    // Too many arguments
    TOO_MANY_ARGUMENTS_RC = -1078,
    // Invalid numeric expression
    INVALID_NUMERIC_EXPRESSION_RC = -1079,
    // Variable {1} not initialized
    VARIABLE_NOT_INITIALIZED_RC = -1080,
    // Control not defined or variable not initialized.  Use _control to define control.
    CONTROL_NOT_DEFINED_RC = -1081,
    // Expecting ex extension for output filename
    INVALID_EXTENSION_RC = -1082,
    // Commands may not take parameters. Use arg function.
    COMMANDS_MAY_NOT_TAKE_PARAM_RC = -1083,
    // Numeric overflow or underflow
    STNUMERIC_OVERFLOW_RC = -1084,
    // Invalid number argument
    STINVALID_NUMBER_ARGUMENT_RC = -1085,
    // Divide by zero
    STDIVIDE_BY_ZERO_RC = -1086,
    // Expecting string of length one
    EXPECTING_STRING_OF_LENGTH_ONE_RC = -1087,
    // Cannot redefine built-in function
    CANT_REDEFINE_FUNCTION_RC = -1088,
    // Recursion too deep
    STRECURSION_TOO_DEEP_RC = -1089,
    // #if not terminated with #endif
    IF_NOT_TERMINATED_RC = -1090,
    // Invalid preprocessor keyword
    INVALID_PREPROCESSOR_KEYWORD_RC = -1091,
    // Must use #if preprocessor keyword before #else/#elseif/#endif
    MUST_USE_IF_PREPROCESSOR_KEYWORD_RC = -1092,
    // #error: {1}
    ERROR_DIRECTIVE_RC = -1093,
    // Preprocessing nested too deep
    PREPROCESSING_NESTED_TD_RC = -1094,
    // Invalid type conversion
    INVALID_TYPE_CONVERSION_RC = -1095,
    // Control name must have parent form
    CONTROL_NAME_MUST_HAVE_PARENT_FORM_RC = -1096,
    // This property can not be set when declared
    CANT_BE_WHEN_DECLARED_RC = -1097,
    // This property is read only
    PROPERTY_IS_READ_ONLY_RC = -1098,
    // Expecting property name
    EXPECTING_PROPERTY_NAME_RC = -1099,
    // Expecting ENDSUBMENU to terminate SUBMENU statement
    EXPECTING_ENDSUBMENU_RC = -1100,
    // Property misspelled or invalid identifier
    PROPERTY_MISSPELLED_RC = -1101,
    // Command line too long.
    ST_CMDLINE_TOO_LONG_RC = -1102,
    // Unable to open conversion file convert.tmp.
    UO_CONVERSION_FILE_RC = -1103,
    // Expecting ':'
    ST_EXPECTING_COLON_RC = -1104,
    // Left operand must be lvalue
    LEFT_OPERAND_MUST_BE_LVALUE_RC = -1105,
    // For your protection, the assignment operator is not allowed here
    ASSIGNMENT_OPERATOR_NOT_ALLOWED_RC = -1106,
    // Expecting '}'
    EXPECTING_RIGHT_BRACE_RC = -1107,
    // Expecting statement
    EXPECTING_STATEMENT_RC = -1108,
    // Expecting while expression after do statement
    EXPECTING_WHILE_RC = -1109,
    // Expecting '{'
    EXPECTING_LEFT_BRACE_RC = -1110,
    // Expecting type name
    EXPECTING_TYPE_NAME_RC = -1111,
    // Expecting defproc to follow static
    EXPECTING_DEFPROC_RC = -1112,
    // Old keyword no longer supported
    OLD_KEYWORD_NOT_SUPPORTED_RC = -1113,
    // Use property name instead of dot variable
    USE_PROPERTY_NAME_RC = -1114,
    // Object does not allow nested controls
    OBJECT_DOES_NOT_ALLOW_NESTED_CONTROLS_RC = -1115,
    // Use defeventtab to define an event table first
    USE_DEFEVENTTAB_TO_DEFINE_AN_EVENT_TABLE_FIRST_RC = -1116,
    // Use defeventtab to define the form this control belongs to
    USE_DEFEVENTTAB_TO_DEFINE_THE_DEFAULT_FORM_RC = -1117,
    // Control not declared.  Use _control to declare a control
    CONTROL_NOT_DECLARED_RC = -1118,
    // Void function can not return value
    VOID_FUNCTION_CAN_NOT_RETURN_VALUE_RC = -1119,
    // Expecting submenu
    EXPECTING_SUBMENU_RC = -1120,
    // Expecting menu item
    EXPECTING_MENU_ITEM_RC = -1121,
    // Expecting command
    EXPECTING_COMMAND_RC = -1122,
    // Expecting help command
    EXPECTING_HELP_COMMAND_RC = -1123,
    // Expecting help string
    EXPECTING_HELP_STRING_RC = -1124,
    // Ambiguous expression too complex
    AMBIGUOUS_EXPRESSION_TOO_COMPLEX_RC = -1125,
    // Expecting ']'
    EXPECTING_RIGHT_BRACKET_RC = -1126,
    // There is a call to '{1}' with an uninitialized variable
    STCALL_WITH_UNINITIALIZED_VARIABLE_RC = -1127,
    // There is a call to '{1}' with not enough arguments
    STCALL_WITH_NOT_ENOUGH_ARGUMENTS_RC = -1128,
    // Static functions with block scope are illegal
    STATIC_FUNCTIONS_WITH_BLOCK_SCOPE_RC = -1129,
    // Local function prototypes are not supported yet
    LOCAL_FUNCTION_PROTO_TYPES_NOT_SUPPORTED_RC = -1130,
    // Local initializers for statics are not supported yet
    LOCAL_INITIALIZER_NOT_SUPPORTED_RC = -1131,
    // Internal compiler error
    INTERNAL_COMPILER_ERROR_RC = -1132,
    // Member functions not allowed
    MEMBER_FUNCTIONS_NOT_SUPPORTED_RC = -1133,
    // Only argument reference types are supported
    ONLY_ARGUMENT_REFERENCE_TYPES_ARE_SUPPORTED_RC = -1134,
    // Cannot initialize variables of this type
    CANT_INITIALIZE_VARIABLES_OF_THIS_TYPE_RC = -1135,
    // Invalid reference type
    INVALID_REFERENCE_TYPE_RC = -1136,
    // Syntax error
    SYNTAX_ERROR_RC = -1137,
    // Expecting struct type name
    EXPECTING_STRUCT_TYPE_NAME_RC = -1138,
    // Invalid use of void
    INVALID_USE_OF_VOID_RC = -1139,
    // Invalid use of function type
    INVALID_USE_OF_FUNCTION_TYPE_RC = -1140,
    // Function requires more parameters
    FUNCTION_REQUIRES_MORE_PARAMETERS_RC = -1141,
    // Parameter {1} type mismatch
    INCOMPATIBLE_PARAMETER_RC = -1142,
    // Parameter {1} type mismatch. Explicit cast needed to convert {2} to {3}
    INCOMPATIBLE_PARAMETER2_RC = -1143,
    // Parameter {1} type mismatch. Use (expression!=0) to convert expression to boolean
    INCOMPATIBLE_PARAMETER3_RC = -1144,
    // Parameter {1} type mismatch. Cannot convert {2} to {3}
    INCOMPATIBLE_PARAMETER4_RC = -1145,
    // Return type incompatible with function declaration
    RETURN_TYPE_MISMATCH_RC = -1146,
    // return() type mismatch. Explicit cast needed to convert {2} to {3}
    RETURN_TYPE_MISMATCH2_RC = -1147,
    // return() type mismatch. Use (expression!=0)
    RETURN_TYPE_MISMATCH3_RC = -1148,
    // return() type mismatch. Cannot convert {2} to {3}
    RETURN_TYPE_MISMATCH4_RC = -1149,
    // Type mismatch
    TYPE_MISMATCH_RC = -1150,
    // Type mismatch. Explicit cast needed to convert {2} to {3}
    TYPE_MISMATCH2_RC = -1151,
    // Type mismatch. Use (expression!=0)
    TYPE_MISMATCH3_RC = -1152,
    // Type mismatch. Cannot convert {2} to {3}
    TYPE_MISMATCH4_RC = -1153,
    // Incompatible type used with operator {1}
    INCOMPATIBLE_TYPE_USED_WITH_OPERATOR_RC = -1154,
    // Instance expression must be integer compatible
    INSTANCE_EXPRESSION_MUST_BE_INTEGER_COMPATIBLE_RC = -1155,
    // Type of expression must be simple or pointer
    TYPE_OF_EXPRESSION_MUST_BE_SIMPLE_OR_PTR_RC = -1156,
    // Expression incompatible with string type
    EXPRESSION_INCOMPATIBLE_WITH_STRING_TYPE_RC = -1157,
    // Unknown size
    UNKNOWN_SIZE_RC = -1158,
    // {1} is not a member of this struct/class/union
    ID_NOT_MEMBER_RC = -1159,
    // Expecting union type name
    EXPECTING_UNION_TYPE_NAME_RC = -1160,
    // Initialization needs curly braces
    INITIALIZATION_NEEDS_CURLY_BRACES_RC = -1161,
    // Pointer initializations support zero only
    POINTER_INITIALIZATION_SUPPORT_ZERO_ONLY_RC = -1162,
    // struct/union/array/hash table initialization requires '{'
    STRUCT_INITIALIZATION_REQUIRES_LEFT_BRACE_RC = -1163,
    // Expecting '=>' for hash table or array initialization
    EXPECTING_EQGT_RC = -1164,
    // Expecting '[' for array type
    EXPECTING_LEFT_BRACKET_RC = -1165,
    // Expecting ':[' for hash table type
    EXPECTING_COLON_LEFT_BRACKET_RC = -1166,
    // static function '{1}' used but not defined
    STATIC_FUNCTION_NOT_DEFINED_RC = -1167,
    // Expression does not evaluate to a function
    EXPRESSION_DOES_NOT_EVALUATE_TO_A_FUNCTION_RC = -1168,
    // Control '{1}' must be declared or cannot be a member of non-struct/union/class type
    CONTROL_NOT_DEFINED_OR_MEMBERS_NOT_SUPPORTED_RC = -1169,
    // Unknown pragma
    UNKNOWN_PRAGMA_RC = -1170,
    // Bad pragma parameter
    BAD_PRAGMA_PARAMETER_RC = -1171,
    // Identifier '{1}' not declared
    ID_NOT_DECLARED_RC = -1172,
    // This use of function pointers not allowed for your protection
    THIS_USE_OF_FUNCTION_POINTERS_NOT_ALLOWED_RC = -1173,
    // Not all control paths return a value
    NOT_ALL_CONTROL_PATHS_RETURN_A_VALUE_RC = -1174,
    // Label {2} already defined
    LABEL_ALREADY_DEFINED_RC = -1175,
    // Only loops may be labeled
    ONLY_LOOPS_MAY_BE_LABELED_RC = -1176,
    // Loop label not found
    LOOP_LABEL_NOT_FOUND_RC = -1177,
    // Incompatible parse variable type. Declare variable as _str or typeless.
    INCOMPATIBLE_PARSE_VARIABLE_TYPE_RC = -1178,
    // Incompatible type for {1}. Explicit cast needed to convert {2} to {3}
    INCOMPATIBLE_TYPE_FOR_X_EXPLICIT_CAST_NEEDED_FROM_X_TO_X_RC = -1179,
    // Incompatible type for {1}. Cannot convert {2} to {3}
    INCOMPATIBLE_TYPE_FOR_X_CANT_CONVERT_X_TO_X_RC = -1180,
    // Type mismatch for operator {1}
    TYPE_MISMATCH_FOR_OPERATOR_RC = -1181,
    // Incompatible type for {1}. Use (expression!=0)
    INCOMPATIBLE_TYPE_FOR_X_USE_NOT_EQ_ZERO_RC = -1182,
    // Cast of {1} to {2} is not valid
    CAST_OF_X_TO_X_NOT_VALID_RC = -1183,
    // Invalid cast
    INVALID_CAST_RC = -1184,
    // Parameter {1} is call by reference.  Use variable or constant.
    PARAMETER_X_IS_CALL_BY_REFERENCE_RC = -1185,
    // Method not available for variables of this type
    METHOD_NOT_AVAILABLE_RC = -1186,
    // Too many arguments. Add ellipse ('...') argument if this function accepts a variable number of arguments
    TOO_MANY_ARGUMENTS_VARARG_FUNCTIONS_REQUIRE_ELLIPSE_RC = -1187,
    // "{1}" {2} {3}:
    SPACEFILEPOS_RC = -1188,
    // unexpected tokens following preprocessing directive - expected a newline
    ST_UNEXPECTED_TOKENS_RC = -1189,
    // expected macro formal parameter
    ST_EXPECTED_MACRO_FORMAL_PARAMETER_RC = -1190,
    // macro redefinition
    ST_MACRO_REDEFINITION_RC = -1191,
    // reuse of macro formal parameter {2}
    ST_REUSE_OF_FORMAL_PARAMETER_RC = -1192,
    // not enough actual parameters for macro '{2}'
    ST_NOT_ENOUGH_ACTUAL_PARAMETERS_FOR_MACRO_RC = -1193,
    // too many actual parameters for macro '{2}'
    ST_TOO_MANY_ACTUAL_PARAMETERS_FOR_MACRO_RC = -1194,
    // unexpected end of file in macro expansion
    ST_UNEXPECTED_END_OF_FILE_IN_MACRO_EXPANSION_RC = -1195,
    // Internal error in LexIsNextSym
    INTERNAL_ERROR_LEXISNEXTSYM_RC = -1196,
    // Error in default argument value {1}
    ERROR_IN_DEFAULT_ARGUMENT_VALUE_RC = -1197,
    // null can not be assigned to variables of this type
    NULL_CAN_NOT_BE_ASSIGNED_RC = -1198,
    // Invalid unicode escape sequence
    INVALID_UNICODE_ESCAPE_SEQUENCE_RC = -1199,
    // Characters above 127 are code page dependant.  Specify unicode with \uXXXX or binary bytes with \ddd
    NON_PORTABLE_STRING_RC = -1200,
    // Expecting class type name
    EXPECTING_CLASS_TYPE_NAME_RC = -1201,
    // The 'call' statement is deprecated
    CALL_STATEMENT_DEPRECATED_RC = -1202,
    // 'const' declarations are deprecated
    CONST_DECLARATION_DEPRECATED_RC = -1203,
    // Expecting enumerated type name
    EXPECTING_ENUM_TYPE_NAME_RC = -1204,
    // Enumerated flags out of bits (max 64)
    ENUM_FLAGS_OUT_OF_BITS_RC = -1205,
    // Expecting namespace name
    EXPECTING_NAMESPACE_NAME_RC = -1206,
    // Expecting interface type name
    EXPECTING_INTERFACE_TYPE_NAME_RC = -1207,
    // Expecting function prototype
    EXPECTING_FUNCTION_PROTOTYPE_RC = -1208,
    // Expecting member function, not prototype
    EXPECTING_MEMBER_FUNCTION_RC = -1209,
    // Identifier '{1}.{2}' conflicts with one already defined
    IDENTIFIER_ALREADY_DEFINED_CONFLICT_RC = -1210,
    // Local classes are not supported
    LOCAL_CLASSES_NOT_SUPPORTED_RC = -1211,
    // Interfaces, classes, and unions can not have static methods
    INTERFACES_CANNOT_HAVE_STATIC_METHODS_RC = -1212,
    // Interfaces, classes, and unions can not have extern methods
    INTERFACES_CANNOT_HAVE_EXTERN_METHODS_RC = -1213,
    // Access modifier is not allowed here
    ACCESS_MODIFIERS_NOT_ALLOWED_HERE_RC = -1214,
    // Command definition is not allowed here
    COMMAND_NOT_ALLOWED_HERE_RC = -1215,
    // Only one of public, protected, or private modifier allowed
    ONLY_ONE_ACCESS_MODIFIER_ALLOWED_RC = -1216,
    // Interface function '{1}.{2}' not implemented
    INTERFACE_FUNCTION_NOT_IMPLEMENTED_RC = -1217,
    // Member function signature does not match parent class or interface
    MEMBER_FUNCTION_SIGNATURE_DOES_NOT_MATCH_PARENT_RC = -1218,
    // Multiple class inheritance is not allowed
    MULTIPLE_CLASS_INHERITANCE_NOT_ALLOWED_RC = -1219,
    // Extern is only allowed for functions prototypes
    EXTERN_IS_ONLY_FOR_PROTOTYPES_RC = -1220,
    // 'this' is only allowed in non-static class methods
    THIS_NOT_ALLOWED_HERE_RC = -1221,
    // Constructors and destructors can not be static
    CONSTRUCTORS_AND_DESTRUCTORS_CAN_NOT_BE_STATIC_RC = -1222,
    // Interfaces can not constructors or destructors
    INTERFACES_CAN_NOT_HAVE_CONSTRUCTORS_OR_DESTRUCTORS_RC = -1223,
    // A class can have only one constructor and one destructor
    CONSTRUCTORS_AND_DESTRUCTORS_CAN_NOT_OVERLOAD_RC = -1224,
    // Arguments for constructors must have default values
    CONSTRUCTOR_ARGUMENTS_MUST_HAVE_DEFAULTS_RC = -1225,
    // Destructors can not have arguments
    DESTRUCTORS_CAN_NOT_HAVE_ARGUMENTS_RC = -1226,
    // Local variable '{1}' can not be auto declared, function must first be declared
    AUTO_DECLARATOR_REQUIRES_PROTOTYPE_RC = -1227,
    // Private symbol '{1}' is not visible in this scope
    PRIVATE_SYMBOL_NOT_VISIBLE_IN_THIS_SCOPE_RC = -1228,
    // Protected symbol '{1}' is not visible in this scope
    PROTECTED_SYMBOL_NOT_VISIBLE_IN_THIS_SCOPE_RC = -1229,
    // Expecting static class member
    EXPECTING_STATIC_CLASS_MEMBER_RC = -1230,
    // Initializer lists are not supported for class types
    INITIALIZER_LISTS_NOT_SUPPORTED_FOR_CLASSES_RC = -1231,
    // Nested class definitions are not allowed
    NESTED_CLASSES_NOT_ALLOWED_RC = -1232,
    // '{1}' declaration is not allowed in local scope
    DECLARATION_NOT_ALLOWED_IN_LOCAL_SCOPE_RC = -1233,
    // Call to base class constructor must be before any other statements
    BASE_CLASS_CONSTRUCTOR_MUST_BE_FIRST_RC = -1234,
    // Keyword '{1}' is not yet supported
    KEYWORD_NOT_SUPPORTED_YET_RC = -1235,
    // Local variable requires initializer unless function parameter is pass by reference
    AUTO_DECLARATOR_REQUIRES_REFERENCE_TYPE_RC = -1236,
    // Auto type inference is only for simple variable types
    AUTO_DECLARATOR_ONLY_FOR_VARIABLES_RC = -1237,
    // Expecting class instance on left hand side of 'instanceof'
    INSTANCEOF_REQUIRES_CLASS_INSTANCE_ON_LHS_RC = -1238,
    // Expecting class name on right hand side of 'instanceof'
    INSTANCEOF_REQUIRES_CLASS_NAME_ON_RHS_RC = -1239,
    // All class members must come before constructor
    CLASS_MEMBERS_MUST_COME_BEFORE_CONSTRUCTOR_RC = -1240,
    // Class '{1}' does not have a constructor
    CLASS_HAS_NO_CONSTRUCTOR_RC = -1241,
    // Loop statement must have a break or return
    INFINITE_LOOP_RC = -1242,
    // Parenthesized initializers are not allowed for non-static class members
    PARENTHESIZED_INITIALIZERS_NOT_ALLOWED_RC = -1243,
    // Macros with defmain may not be #import'ed
    MACROS_WITH_DEFMAIN_MAY_NOT_BE_IMPORTED_RC = -1244,
    // Expecting '{' or ';'
    EXPECTING_LEFT_BRACE_OR_SEMICOLON_RC = -1245,
    // Using directive is not allowed in a scoped namespace
    USING_NOT_ALLOWED_IN_SCOPED_NAMESPACE_RC = -1246,
    // #include and #import are not allowed inside namespace
    INCLUDE_IS_NOT_ALLOWED_INSIDE_NAMESPACE_RC = -1247,
    // Namespace '{1}' not found
    NAMESPACE_NOT_FOUND_RC = -1248,
    // Expecting 'in'
    EXPECTING_IN_RC = -1249,
    // The 'in' keyword is only allowed in foreach statements
    UNEXPECTED_IN_KEYWORD_RC = -1250,
    // Incompatible type used with foreach
    INCOMPATIBLE_TYPE_USED_WITH_FOREACH_RC = -1251,
    // Namespace names must be all lower case (ex. sc.lang)
    IRREGULAR_NAMESPACE_NAME_RC = -1252,
    // Interface names must be mixed case and start with I (ex. IIterable)
    IRREGULAR_INTERFACE_NAME_RC = -1253,
    // Class names must be mixed case and start with uppercase (ex. StringUtil)
    IRREGULAR_CLASS_NAME_RC = -1254,
    // Enumerated types must be mixed case and start with uppercase (ex. JavaTokens)
    IRREGULAR_ENUMERATED_TYPE_NAME_RC = -1255,
    // Enumerators must be all upper case (ex. JS_WHILE_TOKEN)
    IRREGULAR_ENUMERATOR_NAME_RC = -1256,
    // Member variables must be mixed case and start with 'm_' (ex. m_syntaxIndent)
    IRREGULAR_MEMBER_VARIABLE_NAME_RC = -1257,
    // Static member variables must be mixed case and start with 's_' (ex. s_lastProjectName)
    IRREGULAR_STATIC_VARIABLE_NAME_RC = -1258,
    // Member functions must be mixed case and start with lowercase (ex. getSyntaxHandler)
    IRREGULAR_METHOD_NAME_RC = -1259,
    // Variables in namespaces must be mixed case and start with 'g_' (ex. g_currentProjectName)
    IRREGULAR_NAMESPACE_VARIABLE_NAME_RC = -1260,
    // Functions and commands in namespace names must be all lowercase (ex. truncate_string)
    IRREGULAR_NAMESPACE_FUNCTION_NAME_RC = -1262,
    // Classes can only use operator {1} if they implement the sc.lang.IComparable interface
    CLASS_COMPARISON_REQUIRES_COMPARABLE_RC = -1263,
    // Classes can only use operator [] if they implement the sc.lang.IIndexable interface
    CLASS_INDEXING_REQUIRES_INDEXABLE_RC = -1264,
    // Classes can only use operator :[] if they implement the sc.lang.IHashIndexable interface
    CLASS_INDEXING_REQUIRES_HASHINDEXABLE_RC = -1265,
    // Classes can be hashed only if they implement the sc.lang.IHashable interface
    CLASS_HASHING_REQUIRES_HASHABLE_RC = -1266,
    // Classes can be converted to strings only if they implement the sc.lang.IToString interface
    STRING_CONVERSION_REQUIRES_TOSTRING_RC = -1267,
    // #include and #import statements must precede code
    INCLUDES_MUST_BE_FIRST_RC = -1268,
    // Constants must be all upper case (ex. MAX_CACHE_SIZE)
    IRREGULAR_CONSTANT_NAME_RC = -1269,
    // Cast of class '{1}' to unrelated class '{2}' is not valid
    CAST_OF_CLASS_X_TO_X_NOT_VALID_RC = -1270,
    // Member '{1}' already defined as same or different type
    MEMBER_ID_ALREADY_DEFINED_RC = -1271,
    // Member '{1}' already defined as same or different type in superclass
    MEMBER_ID_ALREADY_DEFINED_IN_SUPERCLASS_RC = -1272,
    // Attempt to call deprecated function '{1}'
    FUNCTION_IS_DEPRECATED_RC = -1273,
    // Attempt to use deprecated type name '{1}'
    TYPENAME_IS_DEPRECATED_RC = -1274,
    // Attempt to use deprecated property '{1}'
    PROPERTY_IS_DEPRECATED_RC = -1275,
    // Attempt to use deprecated variable '{1}'
    VARIABLE_IS_DEPRECATED_RC = -1276,
    // Code size too large. String space exceeded.
    OUT_OF_STRING_CODE_SPACE_RC = -1277,
    // Code size too large. Link table space exceeded.
    OUT_OF_LINKTAB_CODE_SPACE_RC = -1278,
    // Standard version macro compiler can't correctly compile system macros
    VSRC_STANDARD_VERSION_CANT_COMPILE_SYSTEM_MACROS = -1279,
    // Attempt to use deprecated constant or enumerator '{1}'
    CONSTANT_IS_DEPRECATED_RC = -1280,
    // The boolean constants are 'true' and 'false', not '1' or '0'
    BOOLEAN_CONSTANT_IS_TRUE_OR_FALSE_RC = -1281,
    // Named argument '{1}' skips parameter that has no default value
    NAMED_ARGUMENT_SKIPS_NON_DEFAULT_PARAMETER_RC = -1282,
    // Named argument '{1}' not found in function prototype
    NAMED_ARGUMENT_NOT_FOUND_IN_PROTOTYPE_RC = -1283,
    // Named argument not allowed here
    NAMED_ARGUMENT_NOT_ALLOWED_RC = -1284,
    // Named variable argument list must be first variable argument
    NAMED_VARIABLE_ARGUMENT_TOO_LATE_RC = -1285,
    // The 'boolean' keyword is deprecated, use 'bool'
    BOOLEAN_KEYWORD_DEPRECATED_RC = -1286,
    // _metadata modifier not supported here
    _METADATA_MODIFIER_NOT_SUPPORTED_HERE_RC=-1287,
    // static modifier not supported here
    STATIC_MODIFIER_NOT_SUPPORTED_HERE_RC=-1288,
    // defeventtab/menu/form identifiers do not support namespaces yet
    NAMESPACES_NOT_SUPPORTED_YET_RC = -1289,
    // struct not yet supported inside a class definition
    NESTED_STRUCTS_NOT_ALLOWED_RC = -1290,
};
#endif

#ifndef VSMSGDEFS_SLICKEDITOR_H
#define VSMSGDEFS_SLICKEDITOR_H
enum VSMSGDEFS_SLICKEDITOR {
    // 
    SLICK_EDITOR_VERSION_RC = -2000,
    // Spill file too large. Save files and exit
    SPILL_FILE_TOO_LARGE_RC = -2001,
    // ON
    ON_RC = -2002,
    // OFF
    OFF_RC = -2003,
    // Expecting ignore or exact
    EXPECTING_IGNORE_OR_EXACT_RC = -2004,
    // Error in margin settings
    ERROR_IN_MARGIN_SETTINGS_RC = -2005,
    // Error in tab settings
    ERROR_IN_TAB_SETTINGS_RC = -2006,
    // Unknown command
    UNKNOWN_COMMAND_RC = -2007,
    // Missing filename
    MISSING_FILENAME_RC = -2008,
    // Too many files
    TOO_MANY_FILES_RC = -2009,
    // Too many selections
    TOO_MANY_SELECTIONS_RC = -2010,
    // Lines truncated
    LINES_TRUNCATED_RC = -2011,
    // Text already selected
    TEXT_ALREADY_SELECTED_RC = -2012,
    // Text not selected
    TEXT_NOT_SELECTED_RC = -2013,
    // Invalid selection type
    INVALID_SELECTION_TYPE_RC = -2014,
    // Source destination conflict
    SOURCE_DEST_CONFLICT_RC = -2015,
    // New file
    NEW_FILE_RC = -2016,
    // Line selection required
    LINE_SELECTION_REQUIRED_RC = -2017,
    // Block selection required
    BLOCK_SELECTION_REQUIRED_RC = -2018,
    // Too many window groups
    TOO_MANY_GROUPS_RC = -2019,
    // Macro file {1} not found
    MACRO_FILE_NOT_FOUND_RC = -2020,
    // Cannot delete root node
    TREE_CANNOT_DELETE_ROOT_NODE_RC = -2021,
    // Hit any key to continue
    HIT_ANY_KEY_RC = -2023,
    // Bottom of file
    BOTTOM_OF_FILE_RC = -2024,
    // Top of file
    TOP_OF_FILE_RC = -2025,
    // Invalid point
    INVALID_POINT_RC = -2026,
    // .  Type any key.
    TYPE_ANY_KEY_RC = -2027,
    // Too many windows
    TOO_MANY_WINDOWS_RC = -2028,
    // Not enough memory
    NOT_ENOUGH_MEMORY_RC = -2029,
    // Press any key to continue
    PRESS_ANY_KEY_TO_CONTINUE_RC = -2030,
    // Spill file I/O error
    SPILL_FILE_IO_ERROR_RC = -2031,
    // .  Type new drive letter
    TYPE_NEW_DRIVE_LETTER_RC = -2032,
    // Nothing to undo
    NOTHING_TO_UNDO_RC = -2033,
    // Nothing to redo
    NOTHING_TO_REDO_RC = -2034,
    // Line or block selection required
    LINE_OR_BLOCK_SELECTION_REQUIRED_RC = -2035,
    // Invalid selection handle
    INVALID_SELECTION_HANDLE_RC = -2036,
    // Searching and Replacing...
    SEARCHING_AND_REPLACING_RC = -2037,
    // Command cancelled
    COMMAND_CANCELLED_RC = -2038,
    // Error creating semaphore
    ERROR_CREATING_SEMAPHORE_RC = -2039,
    // Error creating thread
    ERROR_CREATING_THREAD_RC = -2040,
    // Error creating queue
    ERROR_CREATING_QUEUE_RC = -2041,
    // Process already running
    PROCESS_ALREADY_RUNNING_RC = -2042,
    // Cannot find process init program 'ntpinit'
    CANT_FIND_INIT_PROGRAM_RC = -2043,
    // Command line too long.  Place wild card file specifications in double quotes.
    CMDLINE_TOO_LONG_RC = -2044,
    // 
    SERIAL_NUMBER_RC = -2045,
    // '{1}' is not recognized as a compatible state file or pcode file
    UNRECOGNIZED_STATE_FILE_FORMAT_RC = -2046,
    // 
    PACKAGE_LICENSES_RC = -2047,
    // Unable to create spill file '{1}'
    UNABLE_TO_CREATE_SPILL_FILE_RC = -2049,
    // Unable to display popup
    UNABLE_TO_DISPLAY_POPUP_RC = -2052,
    // Menu handle must be popup
    MENU_HANDLE_MUST_BE_POPUP_RC = -2053,
    // Menu handle can not be popup
    MENU_HANDLE_CAN_NOT_BE_POPUP_RC = -2054,
    // Invalid menu handle
    INVALID_MENU_HANDLE_RC = -2055,
    // Menu handle already attached to window
    MENU_HANDLE_ALREADY_ATTACHED_TO_WINDOW_RC = -2056,
    // This border style does not support menus
    THIS_BORDER_STYLE_DOES_NOT_SUPPORT_MENUS_RC = -2057,
    NOT_USED7_RC = -2058,
    // Command not allowed when activate window is iconized
    COMMAND_NOT_ALLOWED_WHEN_AW_IS_ICON_RC = -2059,
    // Command not allowed when no edit windows present
    COMMAND_NOT_ALLOWED_WHEN_NCW_RC = -2060,
    // slkwait program not found
    SLKWAIT_PROGRAM_NOT_FOUND_RC = -2061,
    // Changes the window size
    SIZE_RC = -2062,
    // Changes the window position
    MOVE_RC = -2063,
    // Closes the window
    CLOSE_RC = -2064,
    // Reduces the window to an icon
    MINIMIZE_RC = -2065,
    // Enlarges the window to full size
    MAXIMIZE_RC = -2066,
    // Switches to the next window
    NEXTWINDOW_RC = -2067,
    // Restores the window to normal size
    RESTORE_RC = -2068,
    // Displays the task list menu
    TASKLIST_RC = -2069,
    // Quits the program
    CLOSE_APPLICATION_RC = -2070,
    // Move, size, or close the document window
    WINDOW_MENU_RC = -2071,
    // Move, size, or close the application window
    APPLICATION_MENU_RC = -2072,
    // This property or method is not allowed on this object
    PROPERTY_OR_METHOD_NOT_ALLOWED_RC = -2073,
    // Unable to create timer
    UNABLE_TO_CREATE_TIMER_RC = -2074,
    // Time out waiting for process to initialized
    TIMEOUT_WATING_FOR_PROCESS_INIT_RC = -2075,
    // Cannot create mdi form object
    CANT_CREATE_MDI_FORM_OBJECT_RC = -2076,
    // Form object can not be clipped child
    FORM_OBJECT_CAN_NOT_BE_CLIPPED_CHILD_RC = -2077,
    // Control objects must have parent
    CONTROL_OBJECTS_MUST_HAVE_PARENT_RC = -2078,
    // Invalid parent window
    INVALID_PARENT_WINDOW_RC = -2079,
    // Invalid sort data
    INVALID_SORT_DATA_RC = -2080,
    // xterm program not found
    XTERM_PROGRAM_NOT_FOUND_RC = -2081,
    // This property or method requires a displayed object
    OBJECT_MUST_BE_DISPLAYED_RC = -2082,
    // Form or control does not have name
    FORM_OR_CONTROL_DOES_NOT_HAVE_NAME_RC = -2083,
    // This operation is not supported with this clipboard format
    CLIPBOARD_OPERATION_NOT_SUPPORTED_RC = -2084,
    // Unable to get clipboard data
    UNABLE_TO_GET_CLIPBOARD_DATA_RC = -2085,
    // Nothing selected
    NOTHING_SELECTED_RC = -2086,
    // System call failed
    SYSTEM_CALL_FAILED_RC = -2087,
    // Invalid object handle
    INVALID_OBJECT_HANDLE_RC = -2088,
    // Failed to load printer driver
    FAILED_TO_LOAD_PRINTER_DRIVER_RC = -2089,
    // ExtDevMode function not found
    EXT_DEVICE_MODE_FUNCTION_NOT_FOUND_RC = -2090,
    // Printer not set up correctly
    PRINTER_NOT_SET_UP_CORRECTLY_RC = -2091,
    // Unable to start printer
    UNABLE_TO_START_PRINTER_RC = -2092,
    // Printing failed
    PRINTER_FAILURE_RC = -2093,
    // The regular expression stack is getting very large due to a complex search string.  You may not have enough memory to complete the search.
    // 
    // Continue?
    LONG_STRING_MATCH_RC = -2094,
    // DDE command not processed
    DDE_NOT_PROCESSED_RC = -2095,
    // DDE server busy
    DDE_BUSY_RC = -2096,
    // Unable to connect to DDE server
    DDE_UNABLE_TO_CONNECT_RC = -2097,
    // DDE error
    DDE_ERROR_RC = -2098,
    // Command not allowed in Read only mode
    COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC = -2099,
    // wemu387.386 not installed or invalid
    WEMU387_NOT_FOUND_OR_INVALID_RC = -2100,
    // Failed to copy/move {1} to {2}
    FAILED_TO_BACKUP_FILE_RC = -2101,
    // Failed to copy/move {1} to {2}.  Access denied.
    FAILED_TO_BACKUP_FILE_ACCESS_DENIED_RC = -2105,
    // Line
    LINE_RC = -2106,
    // Col
    COL_RC = -2107,
    // Ins
    INS_RC = -2108,
    // Rep
    REP_RC = -2109,
    // Demo version cannot save files of this extension.  Please contact sales at SlickEdit Inc. at 800 934-3348 or 919 473-0070.
    DEMO_CANT_SAVE_FILES_RC = -2110,
    // Failed to copy/move {1} to {2}.  Insufficient disk space.
    FAILED_TO_BACKUP_FILE_INSUFFICIENT_DISK_SPACE_RC = -2111,
    // Slick-C(R) cannot call DLL function with pointer to void parameter
    SLICK_C_CANT_CALL_DLL_FUNCTION_WITH_PVOID_RC = -2112,
    // Function not available
    FUNCTION_NOT_AVAILABLE_RC = -2113,
    // Macros with defmain may not be loaded
    MACROS_WITH_DEFMAIN_MAY_NOT_BE_LOADED_RC = -2114,
    // 
    APPNAME_RC = -2115,
    // Failed to communicate with existing instance. 
    // Try runnning SlickEdit again or terminating other instances.
    VSRC_FAILED_TO_COMMUNICATE_WITH_EXISTING_INSTANCE= -2121,
    // Click here to jump to a specific line
    VSRC_LINE_TOOLTIP_RC = -2122,
    // Click here to jump to a specific column
    VSRC_COL_TOOLTIP_RC = -2123,
    // Click here to select a language editing mode
    VSRC_MODE_TOOLTIP_RC = -2124,
    // Click here to toggle read only mode
    VSRC_READWRITE_TOOLTIP_RC = -2125,
    // Click here to toggle insert/replace mode
    VSRC_INSREP_TOOLTIP_RC = -2126,
    // Indicates number of cursors and number of lines or columns selected, click to toggle selection
    VSRC_SELECTION_TOOLTIP_RC = -2127,
    // No Selection
    NO_SELECTION_RC = -2128,
    // Line
    SELECTION_1LINE_RC = -2129,
    // Lines
    SELECTION_LINES_RC = -2130,
    // Col
    SELECTION_1COLUMN_RC = -2131,
    // Cols
    SELECTION_COLUMNS_RC = -2132,
    // Block
    SELECTION_BLOCK_RC = -2133,
    // Click here to toggle macro recording
    VSRC_RECORD_MACRO_TOOLTIP_RC = -2134,
    // Click here to activate alerts!
    VSRC_ALERT_TOOLTIP_RC = -2135,
    // The following line(s) are longer than the allowed limit: {1}
    VSRC_LINES_LONGER_THAN_ALLOWED_LIMIT = -2148,
    // Line truncated to fit within truncate length setting
    VSRC_LINE_TRUNCATED_TO_FIT_WITHIN_TRUNCATE_LENGTH_RC = -2149,
    // This operation is not allowed after truncation length setting
    VSRC_THIS_OPERATION_IS_NOT_ALLOWED_AFTER_TRUNCATION_LENGTH = -2150,
    // This operation would create a line longer than the truncation length setting
    VSRC_THIS_OPERATION_WOULD_CREATE_LINE_TOO_LONG = -2151,
    // The cursor position is past the truncation length setting
    VSRC_CURSOR_POSITION_PAST_TRUNCATION_LENGTH = -2152,
    // This operation is only allowed when the truncation length is zero
    VSRC_OPERATION_ONLY_ALLOWED_WHEN_TRUNCATION_LENGTH_IS_ZERO = -2153,
    // The selection is not valid for this operation
    VSRC_SELECTION_NOT_VALID_FOR_OPERATION = -2154,
    // Record width option is not supported for UNICODE files
    VSRC_RECORD_WIDTH_OPTION_NOT_SUPPORTED_FOR_UTF8 = -2155,
    // Code page not installed or not valid
    VSRC_CODE_PAGE_NOT_INSTALLED_OR_NOT_VALID_RC = -2156,
    // Code page to code page translations not supported
    VSRC_CODE_PAGE_TO_CODE_PAGE_TRANSLATIONS_NOT_SUPPORTED = -2157,
    // This EBCDIC translation is not supported
    VSRC_THIS_EBCDIC_TRANSLATION_IS_NOT_SUPPORTED = -2158,
    // Command is disabled for this object
    VSRC_COMMAND_IS_DISABLED_FOR_THIS_OBJECT_OR_STATE = -2159,
    // This command is not implemented in this version.
    VSRC_COMMAND_NOT_IMPLEMENTED = -2160,
    // Menu {1} not found
    VSRC_MENU_NOT_FOUND = -2161,
    // Missing tool window
    VSRC_TOOL_WINDOW_NOT_FOUND = -2162,
    // Form not found: {1}
    VSRC_FORM_NOT_FOUND = -2163,
    // License expired
    VSRC_LICENSE_EXPIRED = -2164,
    // Must be using QT. VSAPIFLAG_USING_QT not specified
    VSRC_MUST_BE_USING_QT = -2165,
    // Function not supported when using QT. Check for Qt specific function or remove VSAPIFLAG_USING_QT flag
    VSRC_FUNCTION_NOT_SUPPORTED_WHEN_USING_QT = -2166,
    // (location {0}%) Searching...
    VSRC_SEARCHING_STATUS = -2167,
    // (location {0}%) Replaced {1} occurrence
    VSRC_REPLACED_ONE_STATUS = -2168,
    // (location {0}%) Replaced {1} occurrences
    VSRC_REPLACED_MULTIPLE_STATUS = -2169,
    // {0} Cursors
    VSRC_CURSORS_ARG1 = -2170,
    // Multiple instances not supported for form: {0}
    VSRC_TOOL_WINDOW_DOES_NOT_SUPPORT_DUPLICATES = -2171,
    // Invalid buffer id
    VSRC_INVALID_BUFFER_ID = -2172,
    // Feature requires Pro edition
    VSRC_FEATURE_REQUIRES_PRO_EDITION = -2173,
    // State file {0} requires Pro edition
    VSRC_STATE_FILE_REQUIRES_PRO_EDITION_1ARG=-2174,
    // {0} requires Pro edition
    VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG = -2175,
    // Record width too large
    VSRC_RECORD_WIDTH_TOO_LARGE = -2176,
    // No more matches
    VSRC_NO_MORE_MATCHES = -2177,
    // {0}% saved
    VSRC_SAVE_COMPLETION_STATUS = -2178,
    // Application theme not found
    VSRC_APPLICATION_THEME_NOT_FOUND = -2179,
    // Recursion in search function not supported
    VSRC_RECURSION_IN_SEARCH_FUNCTION_NOT_SUPPORTED= -2180,
    // Click here to save the file in a different encoding and/or line format
    VSRC_EOLCHARS_TOOLTIP_RC= -2181,
    // Feature requires Pro or Standard edition
    VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION = -2182,
    // {0} requires Pro or Standard edition
    VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG = -2183,
    // Large file support requires Pro or Standard edition
    VSRC_FILE_TOO_LARGE_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION = -2184,
    // Feature requires Standard edition
    VSRC_FEATURE_REQUIRES_STANDARD_EDITION = -2185,
    // {0} requires Pro or Standard edition
    VSRC_FEATURE_REQUIRES_STANDARD_EDITION_1ARG = -2186,
};
#endif

#ifndef VSMSGDEFS_REGEX_H
#define VSMSGDEFS_REGEX_H
enum VSMSGDEFS_REGEX {
    // Invalid regular expression
    INVALID_REGULAR_EXPRESSION_RC = -2500,
    EOL1_RC = -2501,
    EOL2_RC = -2502,
    RE_EOF_RC = -2503,
    REBREAK_KEY_PRESSED_RC = -2504,
};
#endif

#ifndef VSMSGDEFS_VSCR_H
#define VSMSGDEFS_VSCR_H
enum VSMSGDEFS_VSCR {
    // Unsupported graphics format
    VUNSUPPORTED_GRAPHICS_FORMAT_RC = -2550,
    // Invalid bitmap file
    VINVALID_BITMAP_FILE_RC = -2551,
};
#endif

#ifndef VSMSGDEFS_SLICKI_H
#define VSMSGDEFS_SLICKI_H
enum VSMSGDEFS_SLICKI {
    // Incorrect version
    INCORRECT_VERSION_RC = -3000,
    // No main entry point
    NO_MAIN_ENTRY_POINT_RC = -3001,
    // Interpreter out of memory
    INTERPRETER_OUT_OF_MEMORY_RC = -3002,
    // Procedure {1} not found
    PROCEDURE_NOT_FOUND_RC = -3003,
    // Module already loaded
    MODULE_ALREADY_LOADED_RC = -3006,
    // Cannot remove module
    CANT_REMOVE_MODULE_RC = -3007,
    // Numeric overflow
    NUMERIC_OVERFLOW_RC = -3008,
    // Invalid number argument
    INVALID_NUMBER_ARGUMENT_RC = -3009,
    // Recursion too deep
    RECURSION_TOO_DEEP_RC = -3010,
    // Invalid number of parameters
    INVALID_NUMBER_OF_PARAMETERS_RC = -3011,
    // Out of string space
    OUT_OF_STRING_SPACE_RC = -3012,
    // Expression stack overflow
    EXPRESSION_STACK_OVERFLOW_RC = -3013,
    // Illegal opcode
    ILLEGAL_OPCODE_RC = -3014,
    // Invalid argument
    INVALID_ARGUMENT_RC = -3015,
    // Loop stack overflow
    LOOP_STACK_OVERFLOW_RC = -3016,
    // Divide by zero
    DIVIDE_BY_ZERO_RC = -3017,
    // Invalid call by reference
    INVALID_CALL_BY_REFERENCE_RC = -3018,
    // Procedure needs more arguments
    PROCEDURE_NEEDS_MORE_ARGS_RC = -3019,
    // Break key pressed.  Macro halted
    BREAK_KEY_PRESSED_RC = -3020,
    // Cannot write state during relink
    CANT_WRITE_STATE_DURING_REL_RC = -3021,
    // String not found
    STRING_NOT_FOUND_RC = -3022,
    NOT_USED_1_RC = -3023,
    // Command {1} not found
    COMMAND_NOT_FOUND_RC = -3024,
    // Function is not supported in DOS
    FUNCTION_NOT_SUPPORTED_IN_DOS_RC = -3027,
    // Function is not supported in OS/2
    FUNCTION_NOT_SUPPORTED_IN_OS2_RC = -3028,
    // Invalid name index
    INVALID_NAME_INDEX_RC = -3029,
    // Invalid option
    INVALID_OPTION_RC = -3030,
    // Not enough memory to create menu
    NOT_ENOUGH_MEMORY_TO_CREATE_MENU_RC = -3040,
    // No file active
    NO_FILE_ACTIVE_RC = -3041,
    // Object {1} referenced but does not exist
    OBJECT_REFERENCED_BUT_DOES_NOT_EXIST_RC = -3042,
    // Control {1} referenced but does not exist
    CONTROL_REFERENCED_BUT_DOES_NOT_EXIST_RC = -3045,
    // Event table {1} referenced but does not exist
    EVENT_TABLE_REFERENCED_BUT_DOES_NOT_EXIST_RC = -3048,
    // VSAPI.DLL not found
    VSAPI_DLL_NOT_FOUND_RC = -3051,
    // Error loading DLL '{1}'
    ERROR_LOADING_DLL_RC = -3055,
    // DLL function '{1}' not found
    DLL_FUNCTION_NOT_FOUND_RC = -3058,
    // DLLEXPORT: Invalid DLL type '{1}'
    INVALID_DLLTYPE_RC = -3061,
    // {1}: Invalid argument
    ARGINVALID_ARGUMENT_RC = -3064,
    // Cannot reference deleted element
    DELETED_ELEMENT_RC = -3066,
    // Warning: A large string of length {1} bytes about to be created.
    // 
    // Continue?
    WARNINGSTRINGLEN_RC = -3067,
    // Invalid array
    INVALID_ARRAY_RC = -3070,
    // Variable element or variable not initialized
    ARRAY_OR_HASH_TABLE_ELEMENT_NOT_INITIALIZED_RC = -3071,
    // Invalid VSHVAR argument
    INVALID_HVAR_ARGUMENT_RC = -3072,
    // Invalid pointer argument
    INVALID_POINTER_ARGUMENT_RC = -3073,
    // Module '{1}' contains a call to '{2}' with an uninitialized variable.  Declare a function prototype to find the error at compile time.
    CALL_WITH_UNINITIALIZED_VARIABLE_RC = -3074,
    // Module '{1}' contains a call to '{2}' with not enough arguments  Declare a function prototype to find the error at compile time.
    CALL_WITH_NOT_ENOUGH_ARGUMENTS_RC = -3079,
    // Invalid function pointer
    INVALID_FUNCTION_POINTER_RC = -3084,
    // Warning: A large array of {1} elements about to be created.
    // 
    // Continue?
    WARNINGARRAYSIZE_RC = -3085,
    // Module {1} references control '{2}' which does not exist on form '{3}'.  If this message is incorrect, declare the control using the _nocheck option (see help on _nocheck).
    WARNING_POSSIBLE_REFERENCE_TO_CONTROL_WHICH_DOES_NOT_EXIST_RC = -3088,
    // Cannot subscript stack copy of array or hash table
    CANT_SUBSCRIPT_STACK_COPY_OF_ARRAY_OR_HASH_TABLE_RC = -3095,
    // load_files +c option deprecated.  Use _open_temp_view() or _create_temp_view().
    VSRC_LOAD_FILES_WITH_PLUSC_OPTION_DEPRECATED = -3096,
    // load_files +v view_id option deprecated.  Use +bi view_id.p_buf_id
    VSRC_LOAD_FILES_WITH_PLUSV_OPTION_DEPRECATED = -3097,
    // Class '{1}' not found
    CLASS_NAME_NOT_FOUND_RC = -3098,
    // Class or struct member '{1}' not found
    CLASS_MEMBER_NOT_FOUND_RC = -3099,
    // Expecting variable with class or struct type
    EXPECTING_CLASS_INSTANCE_RC = -3100,
    // Slick-C(R) assertion failure
    SLICKC_ASSERTION_FAILURE_RC = -3101,
    // Attach Slick-C(R) debugger now?
    SLICKC_ATTACH_DEBUGGER_RC = -3102,
    // Usage: vs [Options] file1 [Options] file2
    // 
    // file1 file2		Files to edit. File names may contain ant-like 
    // 		wildcards (**,  *, and ?).
    // + or -new		New instance of the editor.
    // -sc config_path	Specifies the configuration directory.
    // -sr restore_path	Specifies the directory containing auto-restore
    // 		files.
    // -st state_ksize	Specifies the maximum amount of swappable
    // 		state file data in vslick.sta to be kept in memory,
    // 		in kilobytes.
    // -sul		(Unix only) Disables byte-range file locking that SlickEdit
    // 		normally performs. Use this option when receiving
    // 		an 'access denied' error with remote files.
    // -x pcode_name	Alternate state file (.sta) or pcode file (.ex).
    // -p cmdline	Execute command with arguments given and exit.
    // -r cmdline		Execute command with arguments given and
    // 		remain resident.
    // -#command	Execute command on active buffer.
    // + or -L[C]		Turn on/off load entire file switch. The optional
    // 		C suffix specifies counting the number of lines in
    // 		the file.
    // + nnn		Load binary file(s) with a record width of nnn.
    // +T [ buf_name ]	Start a default operating system format temporary
    // 		buffer with name buf_name.
    // +TD [ buf_name ]	Start a DOS format temporary buffer with name
    // 		buf_name.
    // + or -E		Turn on/off expand tabs to spaces when loading
    // 		file. Default is off.
    SLICK_CMD_LINE_USAGE_WIN = -3103,
    // Usage: vs [Options] file1 [Options] file2
    // 
    //    + or -new         New instance of the editor.
    //    -sc config_path   Specifies the configuration directory.
    //    -supf kbdfile     Specifies a keyboard file for mapping the keyboard
    //                      at the X (modmap) level.
    //    -sr restore_path  Specifies the directory containing auto-restore files.
    //    -st state_ksize   Specifies the maximum amount of swappable state file
    //                      data in vslick.sta to be kept in memory, in kilobytes.
    //    -suxft            (Linux only) Disables Xft font support.
    //    -sul              Disables the byte-range file locking that SlickEdit
    //                      normally performs. Enable this option when receiving
    //                      an 'access denied' error with remote files.
    //    -x pcode_name     Alternate state file (.sta) or pcode file (.ex).
    //    -p cmdline        Execute command with arguments given and exit.
    //    -r cmdline        Execute command with arguments given and remain resident.
    //    file1 file2       Files to edit. File names may contain wildcard
    //                      characters (* and ?).
    //    -#command         Execute command on active buffer.
    //    + or -L[C]        Turn on/off load entire file switch. The optional C suffix
    //                      specifies counting the number of lines in the file.
    //    + nnn             Load binary file(s) that follow with a record width nnn.
    //    +T [ buf_name ]   Start a default operating system format temporary buffer
    //                      with name buf_name.
    //    +TU [ buf_name ]  Start a UNIX format temporary buffer with name buf_name.
    //    +TM [ buf_name ]  Start a Macintosh format temporary buffer with name buf_name.
    //                      Classic Mac line endings are a single carriage return (ASCII 13).
    //    + or -E           Turn on/off expand tabs to spaces when loading file. 
    //                      Default is off.
    // 
    SLICK_CMD_LINE_USAGE_NIX = -3104,
    // Slick-C stop operator called.
    SLICK_STOP_OP = -3105,
    // Pro version required to load this macro
    VSRC_PRO_VERSION_VERSION_REQUIRED_TO_LOAD_THIS_MACRO = -3106,
};
#endif

#ifndef VSMSGDEFS_SPELL_H
#define VSMSGDEFS_SPELL_H
enum VSMSGDEFS_SPELL {
    // exist
    SPELL_TEST_RC = -3500,
    // Spell file: {1} not found
    SPELL_FILE_NOT_FOUND_RC = -3501,
    // Unable to open main dictionary: {1}
    SPELL_ERROR_OPENING_MAIN_DICT_FILE_RC = -3504,
    // Unable to open user dictionary: {1}
    SPELL_ERROR_OPENING_USER_DICT_FILE_RC = -3507,
    // Not enough memory
    SPELL_NOT_ENOUGH_MEMORY_RC = -3510,
    // Error reading the main dictionary index: {1}
    SPELL_ERROR_READING_MAIN_INDEX_RC = -3511,
    // Unable to open common word dictionary: {1}
    SPELL_ERROR_OPENING_COMMON_DICT_RC = -3514,
    // Common word dictionary too large
    SPELL_COMMON_DICT_TOO_LARGE_RC = -3517,
    // Error reading the common word dictionary: {1}
    SPELL_ERROR_READING_COMMON_DICT_RC = -3518,
    // User dictionary too large: {1}
    SPELL_USER_DICT_TOO_LARGE_RC = -3521,
    // Error reading the user dictionary: {1}
    SPELL_ERROR_READING_USER_DICT_RC = -3524,
    // Unable to update the user dictionary: {1}
    SPELL_ERROR_UPDATING_USER_DICT_FILE_RC = -3527,
    // Access denied writing the file: {1}
    SPELL_ACCESS_DENIED_RC = -3530,
    // Out of disk space trying to write: {1}
    SPELL_OUT_OF_DISK_SPACE_RC = -3533,
    // Error reading the main dictionary
    SPELL_ERROR_READING_MAIN_DICT_RC = -3536,
    // Word not found
    SPELL_WORD_NOT_FOUND_RC = -3537,
    // Word may contain a capitalization error
    SPELL_CAPITALIZATION_RC = -3538,
    // Word too small
    SPELL_WORD_TOO_SMALL_RC = -3539,
    // Word too large
    SPELL_WORD_TOO_LARGE_RC = -3540,
    // Word is invalid
    SPELL_WORD_INVALID_RC = -3541,
    // Word has a replacement
    SPELL_REPLACE_WORD_RC = -3542,
    // Word cannot be inserted into spell history
    SPELL_HISTORY_TOO_LARGE_RC = -3543,
    // User dictionary not loaded
    SPELL_USER_DICT_NOT_LOADED_RC = -3544,
    // No more words to check
    SPELL_NO_MORE_WORDS_RC = -3545,
    // Repeated word encountered
    SPELL_REPEATED_WORD_RC = -3546,
};
#endif

#ifndef VSMSGDEFS_CLEX_H
#define VSMSGDEFS_CLEX_H
enum VSMSGDEFS_CLEX {
    // Not enough memory
    CLEX_NOT_ENOUGH_MEMORY_RC = -3547,
    // Too many multi-line comments defined
    CLEX_TOO_MANY_MLCOMMENTS_DEFINED_RC = -3548,
    // Identifier multi-line comments not supported
    CLEX_IDENTIFIER_MLCOMMENTS_NOT_SUPPORTED_RC = -3549,
    // Too many checkfirst line comments defined
    CLEX_TOO_MANY_CFLINECOMMENTS_DEFINED_RC = -3550,
    // IDCHARS and CASE-SENSITIVE must be defined first
    CLEX_IDCHARS_MUST_BE_DEFINED_FIRST_RC = -3551,
    // Invalid style
    CLEX_INVALID_STYLE_RC = -3552,
    // Invalid MLCOMMENT definition
    CLEX_INVALID_MLCOMMENT_RC = -3553,
    // Invalid LINECOMMENT definition
    CLEX_INVALID_LINECOMMENT_RC = -3554,
    // Invalid name
    CLEX_INVALID_NAME_RC = -3555,
    // File not found
    CLEX_FILE_NOT_FOUND_RC = -3556,
    // Access denied
    CLEX_ACCESS_DENIED_RC = -3557,
    // Unable to open file
    CLEX_UNABLE_TO_OPEN_FILE_RC = -3558,
    // Invalid idchars definition
    CLEX_INVALID_IDCHARS_RC = -3559,
    // No color coding information for this file 
    CLEX_NO_INFO_FOR_FILE_RC = -3560,
    // Invalid start_col
    CLEX_INVALID_START_COL_RC= -3561,
    // Invalid end_col
    CLEX_INVALID_END_COL_RC= -3562,
    // Invalid flag
    CLEX_INVALID_FLAG_RC= -3563,
    // attrs element has invalid attribute
    CLEX_INVALID_ATTRS_ATTRIBUTE_RC= -3564,
    // match_fun attribute must be set to 'match_comment'
    CLEX_INVALID_MATCH_FUN_RC= -3565,
    // Invalid color
    CLEX_INVALID_COLOR_RC= -3566,
    // Invalid case_sensitive value
    CLEX_INVALID_CASE_SENSITIVE_VALUE_RC= -3567,
    // Invalid escape_char value
    CLEX_INVALID_ESCAPE_CHAR_VALUE_RC= -3568,
    // Invalid line_continuation_char value
    CLEX_INVALID_DOUBLES_CHAR_VALUE_RC= -3569,
    // Invalid line_continuation_char value
    CLEX_INVALID_LINE_CONTINUATION_CHAR_VALUE_RC= -3570,
    // Multi-line comment not found
    CLEX_MLCOMMENT_NOT_FOUND_RC= -3571,
    // Invalid wordchars definition
    CLEX_INVALID_WORDCHARS_RC = -3572,
    // Color coding profile '{0}' not found
    CLEXRC_PROFILE_NOT_FOUND_1ARG = -3573,
    // Color coding profile '{0}': Invalid idchars '{1}'
    CLEXRC_INVALID_IDCHARS_2ARG = -3574,
    // Color coding profile '{0}': Invalid flag '{1}'
    CLEXRC_INVALID_FLAG_2ARG = -3575,
    // Color coding profile '{0}': Invalid start_col '{1}'
    CLEXRC_INVALID_START_COL_2ARG = -3575,
    // Color coding profile '{0}': Invalid end_col '{1}'
    CLEXRC_INVALID_END_COL_2ARG = -3575,

    // Color coding profile '{0}': Invalid end_start_col '{1}'
    CLEXRC_INVALID_END_START_COL_2ARG = -3576,
    // Color coding profile '{0}': Invalid end_end_col '{1}'
    CLEXRC_INVALID_END_END_COL_2ARG = -3577,
    // Color coding profile '{0}': Invalid start_color '{1}'
    CLEXRC_INVALID_START_COLOR_2ARG = -3578,
    // Color coding profile '{0}': Invalid color_to_eol color '{1}'
    CLEXRC_INVALID_COLOR_TO_EOL_2ARG = -3579,
    // Color coding profile '{0}': Invalid end_color '{1}'
    CLEXRC_INVALID_END_COLOR_2ARG = -3580,
    // Color coding profile '{0}': Invalid end_color_to_eol color '{1}'
    CLEXRC_INVALID_END_COLOR_TO_EOL_2ARG = -3581,
    // Color coding profile '{0}': Invalid type '{1}'
    CLEXRC_INVALID_TYPE_2ARG = -3582,

    // Color coding profile '{0}': Invalid case_sensitive value '{1}'
    CLEXRC_INVALID_CASE_SENSITIVE_VALUE_2ARG = -3583,
    // Color coding profile '{0}': Invalid escape_char value '{1}'
    CLEXRC_INVALID_ESCAPE_CHAR_VALUE_2ARG = -3584,
    // Color coding profile '{0}': Invalid doubles_char value '{1}'
    CLEXRC_INVALID_DOUBLES_CHAR_VALUE_2ARG = -3585,
    // Color coding profile '{0}': Invalid line_continuation_char value '{1}'
    CLEXRC_INVALID_LINE_CONTINUATION_CHAR_VALUE_2ARG = -3586,
    // Color coding profile '{0}': Invalid attrs attribute '{1}'
    CLEXRC_INVALID_ATTRS_ATTRIBUTE_2ARG = -3587,
    // Color coding profile '{0}': Invalid regular expression '{1}'
    CLEXRC_INVALID_REGULAR_EXPRESSION_2ARG = -3588,
    // Color coding profile '{0}': Invalid wordchars '{1}'
    CLEXRC_INVALID_WORDCHARS_2ARG = -3589,
    // Color coding profile '{0}': Invalid style '{1}'
    CLEXRC_INVALID_STYLE_2ARG = -3590,
    // Color coding profile '{0}': Invalid mn_flag '{1}'
    CLEXRC_INVALID_MN_FLAG_2ARG = -3591,
    // Color coding profile '{0}': tag comment '{1}'
    CLEXRC_TAG_COMMENT_NOT_FOUND_2ARG = -3592,
    // Color coding profile '{0}': Invalid regular expression '{1}' from text '{2}'
    CLEXRC_INVALID_REGULAR_EXPRESSION_FROM_3ARG = -3593,
    // Color coding profile '{0}': Invalid order value '{1}'
    CLEXRC_INVALID_ORDER_2ARG = -3594,
};
#endif

#ifndef VSMSGDEFS_GREP_H
#define VSMSGDEFS_GREP_H
enum VSMSGDEFS_GREP {
    // Usage:  {3}  [options] [pattern] [[-l] filename [[-l] filename ...]]
    //       -c            Only print count of matches after filename and line
    //                     and column of first match.
    //       -d infile outfile  Creates a patched version of Slick Grep which uses the
    //                          case sensitivity & R. E. search settings specified.
    //       -e pattern    Useful if expression or string starts with '-'.
    //       -f filename   Regular expression or string taken from file.
    //       -fb filename  Binary. Same as above except all characters count.
    //       -h or ?       This help.
    //   {1} -i            Ignore case.
    //       -l filename   Search files listed in filename.
    //       -m            Minimal output.  No filename, line, and column.
    //   {2} -n            Normal search.
    //       {4}-r, {5}-u        SlickEdit or Perl regular expression searching.
    //       -po           Print offset instead of line number and column.
    //       -t            Tree file list.
    //       -w            Whole word search. Words contain [A-Za-z0-9_$].
    //       -w=reg-exp    Whole word search. reg-exp specifies word characters.
    //   {7} -x            Exact case.
    //    Example
    //         {3} BUFSIZE *.c *.h
    //         {3} -i -d {3}{0} my{3}{0}
    //         {3} -i -300 601 James dbase.fil
    // 
    GREP_USAGE_RC = -3600,
    // Grep: Expecting two file names
    GREP_EXECTING_TWO_FILENAMES_RC = -3625,
    // Grep: Expecting pattern string
    GREP_EXPECTING_PATTERN_STRING_RC = -3626,
    // Grep: Pattern already specified
    GREP_PATTERN_STRING_ALREADY_SPECIFIED_RC = -3627,
    // Grep: Expecting filename
    GREP_EXPECTING_FILENAME_RC = -3628,
    // Grep: Unable to open expression file '{1}'
    GREP_UNABLE_TO_OPEN_EXPRESSION_FILE_RC = -3629,
    // Grep: Must specify pattern before files
    GREP_MUST_SPECIFY_PATTERN_BEFORE_FILES_RC = -3630,
    // Grep: unknown option '{1}' ignored
    GREP_UNKNOWN_OPTION_RC = -3631,
    // Grep: Unable to open file '{1}'.  Operation aborted.
    GREP_UNABLED_OPEN_FILE_ABORT_RC = -3632,
    // Grep: Error reading file '{1}'.  Operation aborted.
    GREP_ERROR_READING_FILE_ABORT_RC = -3633,
    // Grep: File name too long.  Operation aborted.
    GREP_FILENAME_TOO_LONG_RC = -3634,
    // Grep: Unable to open input file '{1}'
    GREP_UNABLED_OPEN_INPUT_FILE_RC = -3635,
    // Grep: Unable to open output file '{1}'
    GREP_UNABLED_OPEN_OUTPUT_FILE_RC = -3636,
    // Grep: Unable to find default options
    GREP_UNABLE_TO_FIND_DEFAULT_OPTIONS_RC = -3637,
    // Grep: Unable to write to output file.  Check your disk space.
    GREP_UNABLE_TO_WRITE_TO_OUTPUT_FILE_RC = -3638,
    // Grep: Unable to open file '{1}'.  File skipped
    GREP_UNABLED_OPEN_FILE_SKIPPED_RC = -3639,
    // Grep: Invalid word regular expression
    GREP_INVALID_WORD_RE_RC = -3640,
    // Grep: Invalid regular expression
    GREP_INVALID_RE_RC = -3641,
};
#endif

#ifndef VSMSGDEFS_NTPINIT_H
#define VSMSGDEFS_NTPINIT_H
enum VSMSGDEFS_NTPINIT {
    // This program is only run by SlickEdit
    NTPINIT_ONLY_RUN_BY_SLICKEDIT_RC = -3700,
};
#endif

#ifndef VSMSGDEFS_SLKSHELL_H
#define VSMSGDEFS_SLKSHELL_H
enum VSMSGDEFS_SLKSHELL {
    // If a program prompts for input, you will need to uniconize the
    // SlickEdit Process DOS box and type in your response there.
    SLKSHELL_HELP_RC = -3750,
    // Program '{1}' not found
    SLKSHELL_PROGRAM_NOT_FOUND_RC = -3752,
    // COMSPEC environment variable must be set
    SLKSHELL_COMSPEC_MUST_BE_SET_RC = -3753,
    // Invalid directory
    SLKSHELL_INVALID_DIRECTORY_RC = -3754,
    // The syntax of the command is incorrect.
    SLKSHELL_SYNTAX_INCORRECT_RC = -3755,
};
#endif

#ifndef VSMSGDEFS_SLKWAIT_H
#define VSMSGDEFS_SLKWAIT_H
enum VSMSGDEFS_SLKWAIT {
    // Hit any key to continue
    SLKWAIT_HIT_ANY_KEY_RC = -3800,
    // Press ENTER to continue
    SLKWAIT_PRESS_ENTER_TO_CONTINUE_RC = -3801,
    // If you do not want this console to remain after the program exits, uncheck
    // the "Wait for keypress" option ("Project", "Project Properties...",
    // Tools tab, select the tool name)
    SLKWAIT_JAVA_MESSAGE_RC = -3802,
};
#endif

#ifndef VSMSGDEFS_WDOSRC_H
#define VSMSGDEFS_WDOSRC_H
enum VSMSGDEFS_WDOSRC {
    // TEMP and TMP environment variables not set
    WDOSRC_TEMP_NOT_SET_RC = -3850,
    // Unable to open file {1}
    WDOWRC_UNABLE_TO_OPEN_FILE_RC = -3851,
    // If you are not using DOSKEY or other incompatible retrieve program,
    // you may set the macro variable "def_wshell" to the command shell you
    // want to use (e.g. command.com).  Menu item ("Macro","Set Macro Variable").
    // 
    // If it took about 5 seconds for the concurrent process buffer to start,
    // replace vsutil.dll with vsutil.sho to reduce this time.
    WDOSRC_HELP_RC = -3852,
};
#endif

#ifndef VSMSGDEFS_BTREE_H
#define VSMSGDEFS_BTREE_H
enum VSMSGDEFS_BTREE {
    // Virtual function
    VS_TAG_FLAG_VIRTUAL_RC = -3860,
    // Static
    VS_TAG_FLAG_STATIC_RC = -3861,
    // Public scope
    VS_TAG_FLAG_PUBLIC_RC = -3862,
    // Package scope
    VS_TAG_FLAG_PACKAGE_RC = -3863,
    // Protected scope
    VS_TAG_FLAG_PROTECTED_RC = -3864,
    // Private scope
    VS_TAG_FLAG_PRIVATE_RC = -3865,
    // Const
    VS_TAG_FLAG_CONST_RC = -3866,
    // Final
    VS_TAG_FLAG_FINAL_RC = -3867,
    // Abstract
    VS_TAG_FLAG_ABSTRACT_RC = -3868,
    // Inline function
    VS_TAG_FLAG_INLINE_RC = -3869,
    // Overloaded operator
    VS_TAG_FLAG_OPERATOR_RC = -3870,
    // Class constructor
    VS_TAG_FLAG_CONSTRUCTOR_RC = -3871,
    // Volatile
    VS_TAG_FLAG_VOLATILE_RC = -3872,
    // Template or generic
    VS_TAG_FLAG_TEMPLATE_RC = -3873,
    // Member of class or package
    VS_TAG_FLAG_INCLASS_RC = -3874,
    // Class destructor
    VS_TAG_FLAG_DESTRUCTOR_RC = -3875,
    // Synchronized
    VS_TAG_FLAG_SYNCHRONIZED_RC = -3876,
    // Transient data
    VS_TAG_FLAG_TRANSIENT_RC = -3877,
    // Native code function
    VS_TAG_FLAG_NATIVE_RC = -3878,
    // Created by preprocessor macro
    VS_TAG_FLAG_MACRO_RC = -3879,
    // External function or data
    VS_TAG_FLAG_EXTERN_RC = -3880,
    // Ambiguous prototype/var declaration
    VS_TAG_FLAG_MAYBE_VAR_RC = -3881,
    // Unnamed structure
    VS_TAG_FLAG_ANONYMOUS_RC = -3882,
    // Mutable
    VS_TAG_FLAG_MUTABLE_RC = -3883,
    // Part of external file
    VS_TAG_FLAG_EXTERN_MACRO_RC = -3884,
    // 01 level in Cobol linkage section
    VS_TAG_FLAG_LINKAGE_RC = -3885,
    // Partial class
    VS_TAG_FLAG_PARTIAL_RC = -3886,
    // Ignore/placeholder
    VS_TAG_FLAG_IGNORE_RC = -3887,
    // Forward declaration
    VS_TAG_FLAG_FORWARD_RC = -3888,
    // Opaque enumerated type
    VS_TAG_FLAG_OPAQUE_RC = -3889,
    // Implicitly defined local variable
    VS_TAG_FLAG_IMPLICIT_RC = -3890,
    // Local variable is visible to entire function
    VS_TAG_FLAG_UNSCOPED_RC = -3891,
    // Symbol is to be displayed in Defs tool window only (outline)
    VS_TAG_FLAG_OUTLINE_ONLY_RC = -3892,
    // Symbol is to be hidden in Defs tool window (outline)
    VS_TAG_FLAG_OUTLINE_HIDE_RC = -3893,
    // Symbol overrides an earlier symbol definition
    VS_TAG_FLAG_OVERRIDE_RC = -3894,
    // Symbol shadows or may shadow another local variable.
    VS_TAG_FLAG_SHADOW_RC = -3895,
    // Do not propagate tag flags for this language
    VS_TAG_FLAG_NO_PROPAGATE_RC = -3896,
    // Internal scope
    VS_TAG_FLAG_INTERNAL_RC = -3897,
    // C++ constexpr
    VS_TAG_FLAG_CONSTEXPR_RC = -3898,
    // C++ consteval
    VS_TAG_FLAG_CONSTEVAL_RC = -3899,
    // Database index key already exists
    BT_KEY_ALREADY_EXISTS_RC = -3900,
    // Database record not found
    BT_RECORD_NOT_FOUND_RC = -3901,
    // Unable to read/write database file
    BT_UNABLE_TO_RW_FILE_RC = -3902,
    // Database corrupt
    BT_DATABASE_CORRUPT_RC = -3903,
    // Record length too large
    BT_RECORD_LENGTH_TOO_LARGE_RC = -3904,
    // Incorrect database version
    BT_INCORRECT_VERSION_RC = -3905,
    // Incorrect database magic number
    BT_INCORRECT_MAGIC_RC = -3906,
    // Too many database keys
    BT_TOO_MANY_KEYS_RC = -3907,
    // Database feature not finished
    BT_FEATURE_NOT_FINISHED_RC = -3908,
    // Database field is fixed length, expected variable length
    BT_FIELD_IS_FIXED_LENGTH_RC = -3909,
    // Database field is variable length, expected fixed length
    BT_FIELD_IS_VARIABLE_LENGTH_RC = -3910,
    // Database block is full
    BT_BLOCK_FULL_RC = -3911,
    // Unable to delete database item
    BT_UNABLE_TO_DELETE_RC = -3912,
    // Invalid database block size
    BT_INVALID_BLOCK_SIZE_RC = -3913,
    // Database record is missing a required field
    BT_MISSING_REQUIRED_FIELD_RC = -3914,
    // Unable to update database index
    BT_ERROR_UPDATING_INDEX_RC = -3915,
    // Unable to create database table
    BT_ERROR_CREATING_TABLE_RC = -3916,
    // Unable to create database index
    BT_ERROR_CREATING_INDEX_RC = -3917,
    // Unable to open database table
    BT_ERROR_OPENING_TABLE_RC = -3918,
    // Unable to open database index
    BT_ERROR_OPENING_INDEX_RC = -3919,
    // Database feature not allowed in this context
    BT_FEATURE_NOT_ALLOWED_RC = -3920,
    // Database table not found
    BT_TABLE_NOT_FOUND_RC = -3921,
    // Database index key not found
    BT_KEY_NOT_FOUND_RC = -3922,
    // Database field not found
    BT_FIELD_NOT_FOUND_RC = -3923,
    // Database index not found
    BT_INDEX_NOT_FOUND_RC = -3924,
    // Database internal error
    BT_INTERNAL_ERROR_RC = -3925,
    // Database field not searchable
    BT_FIELD_NOT_SEARCHABLE_RC = -3926,
    // Database table field already exists
    BT_FIELD_ALREADY_EXISTS_RC = -3927,
    // Database table index already exists
    BT_INDEX_ALREADY_EXISTS_RC = -3928,
    // Database table already exists
    BT_TABLE_ALREADY_EXISTS_RC = -3929,
    // Database table field must be named
    BT_FIELD_NAME_REQUIRED_RC = -3930,
    // Database table index must be named
    BT_INDEX_NAME_REQUIRED_RC = -3931,
    // Database table must be named
    BT_TABLE_NAME_REQUIRED_RC = -3932,
    // Database must be named
    BT_DATABASE_NAME_REQUIRED_RC = -3933,
    // Database field is not valid
    BT_FIELD_INVALID_RC = -3934,
    // Invalid database session handle
    BT_INVALID_DB_HANDLE_RC = -3935,
    // Invalid database tag type
    BT_INVALID_TAG_TYPE_RC = -3936,
    // Invalid table handle
    BT_INVALID_TABLE_HANDLE_RC = -3937,
    // Invalid index handle
    BT_INVALID_INDEX_HANDLE_RC = -3938,
    // Invalid file seek position
    BT_INVALID_SEEKPOS_RC = -3939,
    // Database is intended for use on a Unix platform
    BT_DATABASE_IS_FOR_UNIX_RC = -3940,
    // Database is intended for use on a DOS/OS2/NT platform
    BT_DATABASE_IS_FOR_DOS_RC = -3941,
    // Database was opened for read only, modifications are not allowed
    BT_DATABASE_IS_READ_ONLY_RC = -3942,
    // Index handle does not belong to given table
    BT_INDEX_TABLE_MISMATCH_RC = -3943,
    // Can not open database with given block size
    BT_INCORRECT_BLOCKSIZE_RC = -3944,
    // Too many fields in database table
    BT_TOO_MANY_FIELDS_RC = -3945,
    // Too many indexes in database table
    BT_TOO_MANY_INDEXES_RC = -3946,
    // Too many tables in database
    BT_TOO_MANY_TABLES_RC = -3947,
    // Database index node is invalid
    BT_INVALID_NODE_RC = -3948,
    // Database table is invalid
    BT_INVALID_TABLE_RC = -3949,
    // Database header is invalid
    BT_INVALID_DATABASE_RC = -3950,
    // Database block is invalid
    BT_INVALID_BLOCK_RC = -3951,
    // Too many database seek positions in set
    BT_TOO_MANY_SEEKPOS_RC = -3952,
    // Database seek position not found in set
    BT_SEEKPOS_NOT_FOUND_RC = -3953,
    // Database seek position already in set
    BT_SEEKPOS_ALREADY_EXISTS_RC = -3954,
    // Database index node not found
    BT_BRANCH_NOT_FOUND_RC = -3955,
    // Database cache size too small
    BT_CACHE_SIZE_TOO_SMALL_RC = -3956,
    // Invalid tag database file type
    BT_INVALID_FILE_TYPE_RC = -3957,
    // Database session with given file name not found
    BT_SESSION_NOT_FOUND_RC = -3958,
    // Attempt to open too many database sessions at once
    BT_TOO_MANY_SESSIONS_RC = -3959,
    // Database session manager does not allow open for read-write
    BT_READWRITE_NOT_ALLOWED_RC = -3960,
    // Database session manager does not allow creation
    BT_CREATE_NOT_ALLOWED_RC = -3961,
    // Invalid database session handle
    BT_INVALID_SESSION_HANDLE_RC = -3962,
    // Incorrect database application type
    BT_INVALID_DATABASE_TYPE_RC = -3963,
    // No free space in hash node
    BT_HASH_NODE_FULL_RC = -3964,
    // Could not locate previous index in hash node
    BT_HASH_INDEX_NOT_FOUND_RC = -3965,
    // Invalid hash table index
    BT_INVALID_HASH_INDEX_RC = -3966,
    // Invalid hash table size
    BT_INVALID_HASH_NODE_SIZE_RC = -3967,
    // Too many symbols found in context
    BT_TOO_MANY_SYMBOLS_RC = -3968,
    // This database table does not support next/previous record
    BT_TABLE_NO_NEXT_PREV_RC = -3969,
    // Record length too small, four bytes is the minimum
    BT_RECORD_LENGTH_TOO_SMALL_RC = -3970,
    // Memory hash indexes require the table to have next/previous pointers
    BT_INDEX_REQUIRES_NEXT_PREV_RC = -3971,
    // Database feature is obsolete
    BT_FEATURE_IS_OBSOLETE_RC = -3972,
    // Searching: {1}/{2}
    TAGGING_SEARCHING_FOUND_OF_TOTAL_RC = -3973,
    // Time limit for tagging operation expired
    TAGGING_TIMEOUT_RC = -3974,
    // Tag file '{0}' is already being rebuilt.
    TAG_DATABASE_ALREADY_BEING_REBUILT_RC = -3975,
    // Background tagging is not supported for this file.
    BACKGROUND_TAGGING_NOT_SUPPORTED_RC = -3976,
    // Background tagging does not support embedded code blocks.
    EMBEDDED_TAGGING_NOT_SUPPORTED_RC = -3977,
    // Removed file '{0}' from tag file because it is no longer required.
    LEFTOVER_FILE_REMOVED_FROM_DATABASE_RC = -3978,
    // Tagging is not supported for this file.
    TAGGING_NOT_SUPPORTED_FOR_FILE_RC = -3979,
    // Removed file '{0}' from tag file.
    FILE_REMOVED_FROM_DATABASE_RC = -3980,
    // Background tagging is complete for tag file '{0}'
    BACKGROUND_TAGGING_COMPLETE_RC = -3981,
    // Background tagging is searching for files to tag in tag file '{0}'.
    BACKGROUND_TAGGING_IS_FINDING_FILES_RC = -3982,
    // Database size cannot exceed 2GB
    BT_DATABASE_FULL_RC = -3983,
    // Database session should not be closed by a background thread.
    BT_THREADS_CANNOT_CLOSE_FILES_RC = -3984,
    // Can not rebuild a tag file if all the source files are missing.
    TAGGING_CAN_NOT_REBUILD_TAG_FILE_WITH_ALL_FILES_MISSING_RC = -3985,
    // Background tagging was pre-empted by a foreground tagging job.
    BACKGROUND_TAGGING_PREEMPTED_RC = -3986,
    // Invalid or oversized database object 
    BT_OVERSIZED_DATABASE_OBJECT_RC = -3987,
    // Can not write to old version of database
    BT_CANNOT_WRITE_OBSOLETE_VERSION_RC = -3988,
    // Database record already exists in this table or index
    BT_RECORD_ALREADY_EXISTS_RC = -3989,
    // Compressed field was invalid
    BT_FIELD_COMPRESSION_ERROR_RC = -3990,
    // C++ constinit
    VS_TAG_FLAG_CONSTINIT_RC = -3991,
    // Export symbol from module
    VS_TAG_FLAG_EXPORT_RC = -3992,
    // Procedure
    SE_TAG_TYPE_NULL_RC = -4000,
    // Procedure or command
    SE_TAG_TYPE_PROC_RC = -4001,
    // Function prototype
    SE_TAG_TYPE_PROTO_RC = -4002,
    // Preprocessor macro
    SE_TAG_TYPE_DEFINE_RC = -4003,
    // Type alias
    SE_TAG_TYPE_TYPEDEF_RC = -4004,
    // Global variable
    SE_TAG_TYPE_GVAR_RC = -4005,
    // Structure type
    SE_TAG_TYPE_STRUCT_RC = -4006,
    // Enumeration value
    SE_TAG_TYPE_ENUMC_RC = -4007,
    // Enumerated type
    SE_TAG_TYPE_ENUM_RC = -4008,
    // Class type
    SE_TAG_TYPE_CLASS_RC = -4009,
    // Union type
    SE_TAG_TYPE_UNION_RC = -4010,
    // Statement label
    SE_TAG_TYPE_LABEL_RC = -4011,
    // Interface type
    SE_TAG_TYPE_INTERFACE_RC = -4012,
    // Class constructor
    SE_TAG_TYPE_CONSTRUCTOR_RC = -4013,
    // Class destructor
    SE_TAG_TYPE_DESTRUCTOR_RC = -4014,
    // Package, module, or namespace
    SE_TAG_TYPE_PACKAGE_RC = -4015,
    // Member variable
    SE_TAG_TYPE_VAR_RC = -4016,
    // Local variable
    SE_TAG_TYPE_LVAR_RC = -4017,
    // Constant
    SE_TAG_TYPE_CONSTANT_RC = -4018,
    // Function
    SE_TAG_TYPE_FUNCTION_RC = -4019,
    // Class property
    SE_TAG_TYPE_PROPERTY_RC = -4020,
    // Program
    SE_TAG_TYPE_PROGRAM_RC = -4021,
    // Library
    SE_TAG_TYPE_LIBRARY_RC = -4022,
    // Parameter
    SE_TAG_TYPE_PARAMETER_RC = -4023,
    // Package import or using statement
    SE_TAG_TYPE_IMPORT_RC = -4024,
    // Friend relationship
    SE_TAG_TYPE_FRIEND_RC = -4025,
    // Database
    SE_TAG_TYPE_DATABASE_RC = -4026,
    // Database table
    SE_TAG_TYPE_TABLE_RC = -4027,
    // Database column
    SE_TAG_TYPE_COLUMN_RC = -4028,
    // Database index
    SE_TAG_TYPE_INDEX_RC = -4029,
    // Database view
    SE_TAG_TYPE_VIEW_RC = -4030,
    // Database trigger
    SE_TAG_TYPE_TRIGGER_RC = -4031,
    // Form
    SE_TAG_TYPE_FORM_RC = -4032,
    // Menu
    SE_TAG_TYPE_MENU_RC = -4033,
    // Control or widget
    SE_TAG_TYPE_CONTROL_RC = -4034,
    // Event table
    SE_TAG_TYPE_EVENTTAB_RC = -4035,
    // Procedure prototype
    SE_TAG_TYPE_PROCPROTO_RC = -4036,
    // Task
    SE_TAG_TYPE_TASK_RC = -4037,
    // Preprocessor include
    SE_TAG_TYPE_INCLUDE_RC = -4038,
    // File descriptor
    SE_TAG_TYPE_FILE_RC = -4039,
    // Container variable
    SE_TAG_TYPE_GROUP_RC = -4040,
    // Nested function
    SE_TAG_TYPE_SUBFUNC_RC = -4041,
    // Nested procedure or paragraph
    SE_TAG_TYPE_SUBPROC_RC = -4042,
    // Database cursor
    SE_TAG_TYPE_CURSOR_RC = -4043,
    // XML tag
    SE_TAG_TYPE_TAG_RC = -4044,
    // XML tag instance
    SE_TAG_TYPE_TAGUSE_RC = -4045,
    // Statement
    SE_TAG_TYPE_STATEMENT_RC = -4046,
    // Annotation or attribute type
    SE_TAG_TYPE_ANNOTYPE_RC = -4047,
    // Annotation or attribute instance
    SE_TAG_TYPE_ANNOTATION_RC = -4048,
    // Function call
    SE_TAG_TYPE_CALL_RC = -4049,
    // Conditional branch statement
    SE_TAG_TYPE_IF_RC = -4050,
    // Loop statement
    SE_TAG_TYPE_LOOP_RC = -4051,
    // Break statement
    SE_TAG_TYPE_BREAK_RC = -4052,
    // Continue statement
    SE_TAG_TYPE_CONTINUE_RC = -4053,
    // Return statement
    SE_TAG_TYPE_RETURN_RC = -4054,
    // Goto statement
    SE_TAG_TYPE_GOTO_RC = -4055,
    // Try statement
    SE_TAG_TYPE_TRYCATCH_RC = -4056,
    // Preprocessing statement
    SE_TAG_TYPE_PP_RC = -4057,
    // Block statement
    SE_TAG_TYPE_BLOCK_RC = -4058,
    // Mixin construct
    SE_TAG_TYPE_MIXIN_RC = -4059,
    // Build target
    SE_TAG_TYPE_TARGET_RC = -4060,
    // Assignment statement
    SE_TAG_TYPE_ASSIGN_RC = -4061,
    // Objective-C selector
    SE_TAG_TYPE_SELECTOR_RC = -4062,
    // Preprocessor macro #undef
    SE_TAG_TYPE_UNDEF_RC = -4063,
    // Statement sub-clause
    SE_TAG_TYPE_CLAUSE_RC = -4064,
    // Database cluster
    SE_TAG_TYPE_CLUSTER_RC = -4065,
    // Database partition
    SE_TAG_TYPE_PARTITION_RC = -4066,
    // Database audit policy
    SE_TAG_TYPE_POLICY_RC = -4067,
    // Database user profile
    SE_TAG_TYPE_PROFILE_RC = -4068,
    // Database user
    SE_TAG_TYPE_USER_RC = -4069,
    // Database role
    SE_TAG_TYPE_ROLE_RC = -4070,
    // Database sequence type
    SE_TAG_TYPE_SEQUENCE_RC = -4071,
    // Database table space
    SE_TAG_TYPE_TABLESPACE_RC = -4072,
    // Database select statement
    SE_TAG_TYPE_QUERY_RC = -4073,
    // XML or HTML attribute
    SE_TAG_TYPE_ATTRIBUTE_RC = -4074,
    // Database link
    SE_TAG_TYPE_DATABASE_LINK_RC = -4075,
    // Database dimension
    SE_TAG_TYPE_DIMENSION_RC = -4076,
    // Directory
    SE_TAG_TYPE_DIRECTORY_RC = -4077,
    // Database edition
    SE_TAG_TYPE_EDITION_RC = -4078,
    // Database constraint
    SE_TAG_TYPE_CONSTRAINT_RC = -4079,
    // Event monitor
    SE_TAG_TYPE_MONITOR_RC = -4080,
    // Statement scope block
    SE_TAG_TYPE_SCOPE_RC = -4081,
    // Function closure
    SE_TAG_TYPE_CLOSURE_RC = -4082,
    // Class constructor prototype
    SE_TAG_TYPE_CONSTRUCTORPROTO_RC = -4083,
    // Class destructor prototype
    SE_TAG_TYPE_DESTRUCTORPROTO_RC = -4084,
    // Overloaded operator
    SE_TAG_TYPE_OPERATOR_RC = -4085,
    // Overloaded operator prototype
    SE_TAG_TYPE_OPERATORPROTO_RC = -4086,
    // Miscellaneous tag type
    SE_TAG_TYPE_MISCELLANEOUS_RC = -4087,
    // Miscellaneous container tag type
    SE_TAG_TYPE_CONTAINER_RC = -4088,
    // Unknown tag type
    SE_TAG_TYPE_UNKNOWN_RC = -4089,
    // Objective-C static selector
    SE_TAG_TYPE_STATIC_SELECTOR_RC = -4090,
    // Multiple branch or switch statement
    SE_TAG_TYPE_SWITCH_RC = -4091,
    // Source file region
    SE_TAG_TYPE_REGION_RC = -4092,
    // Source file general note
    SE_TAG_TYPE_NOTE_RC = -4093,
    // Source file to-do note (#todo)
    SE_TAG_TYPE_TODO_RC = -4094,
    // Source file warning
    SE_TAG_TYPE_WARNING_RC = -4095,
    // Logic programming rule, Makefile rule, Grammar rule, etc.
    SE_TAG_TYPE_RULE_RC = -4096,
    // Precondition
    SE_TAG_TYPE_PRECONDITION_RC = -4097,
    // Postcondition
    SE_TAG_TYPE_POSTCONDITION_RC = -4098,
    // Guard
    SE_TAG_TYPE_GUARD_RC = -4099,
    // Exported symbol
    SE_TAG_TYPE_EXPORT_RC = -4100,
    // Concept
    SE_TAG_TYPE_CONCEPT_RC = -4101,
    // Module
    SE_TAG_TYPE_MODULE_RC = -4102,
    // Namespace
    SE_TAG_TYPE_NAMESPACE_RC = -4103,

    // Reserved tag type
    SE_TAG_TYPE_FIRSTRESERVED_RC = -4127,
    // User-defined tag type
    SE_TAG_TYPE_FIRSTUSER_RC = -4128,
    // OEM-defined tag type
    SE_TAG_TYPE_FIRSTOEM_RC = -4129,
    // Public or global access
    SE_TAG_TYPE_PICMODIFIER_PUBLIC_RC = -4130,
    // Protected access
    SE_TAG_TYPE_PICMODIFIER_PROTECTED_RC = -4131,
    // Private access
    SE_TAG_TYPE_PICMODIFIER_PRIVATE_RC = -4132,
    // Package level access
    SE_TAG_TYPE_PICMODIFIER_PACKAGE_RC = -4133,
    // Static with public access
    SE_TAG_TYPE_PICMODIFIER_STATIC_PUBLIC_RC = -4134,
    // Static with protected access
    SE_TAG_TYPE_PICMODIFIER_STATIC_PROTECTED_RC = -4135,
    // Static with private access
    SE_TAG_TYPE_PICMODIFIER_STATIC_PRIVATE_RC = -4136,
    // Static with package access
    SE_TAG_TYPE_PICMODIFIER_STATIC_PACKAGE_RC = -4137,
    // Template with public access
    SE_TAG_TYPE_PICMODIFIER_TEMPLATE_PUBLIC_RC = -4138,
    // Template with protected access
    SE_TAG_TYPE_PICMODIFIER_TEMPLATE_PROTECTED_RC = -4139,
    // Template with private access
    SE_TAG_TYPE_PICMODIFIER_TEMPLATE_PRIVATE_RC = -4140,
    // Template with package access
    SE_TAG_TYPE_PICMODIFIER_TEMPLATE_PACKAGE_RC = -4141,
    // Exported with public access
    SE_TAG_TYPE_PICMODIFIER_EXPORT_PUBLIC_RC = -4142,
    // Exported with protected access
    SE_TAG_TYPE_PICMODIFIER_EXPORT_PROTECTED_RC = -4143,
    // Exported with private access
    SE_TAG_TYPE_PICMODIFIER_EXPORT_PRIVATE_RC = -4144,
    // Exported with package access
    SE_TAG_TYPE_PICMODIFIER_EXPORT_PACKAGE_RC = -4145,

    // Mapped tag type
    SE_TAG_TYPE_MAPPED_RC = -4150,
};
#endif

#ifndef VSMSGDEFS_VSMKTAGS_H
#define VSMSGDEFS_VSMKTAGS_H
enum VSMSGDEFS_VSMKTAGS {
    // Usage: vsmktags [Options] Workspace1 [Workspace2] ...
    // 
    //    Workspace(n)      Name of workspace. Multiple workspaces can be specified.
    //    -retag            Retag all files.  Defaults to incremental retagging.
    //    -refs=[on/off]    Enable/disable references.  Defaults to no change.
    //    -thread=[on/off]  Enable/disable threaded tagging.  Default is on.
    //    -sc <configdir>   SlickEdit configuration dir.
    //    -autotag=[lang]   Launch the autotag dialog to build compiler tag files.
    //                        
    // 
    // Example
    //     vsmktags workspace.vpw
    //          Build tag file for all files in workspace.
    // 
    VSMKTAGSRC_USAGE = -4150,
    // Cannot find file '{1}'
    VSMKTAGSRC_CANNOT_FIND_FILE = -4151,
};
#endif

#ifndef VSMSGDEFS_BSC_H
#define VSMSGDEFS_BSC_H
enum VSMSGDEFS_BSC {
    // Expected .BSC file extension
    BSC_INCORRECT_EXTENSION_RC = -4160,
    // Error opening browse database
    BSC_ERROR_OPENING_FILE_RC = -4161,
    // Could not obtain browser database instances
    BSC_NO_INSTANCES_RC = -4162,
    // BSC databases are not supported on this platform
    BSC_ONLY_ON_WINDOWS_RC = -4163,
    // Can not open msbsc50.dll, maybe Visual C++ is not installed
    BSC_CANNOT_OPEN_DLL_RC = -4164,
};
#endif

#ifndef VSMSGDEFS_JAVA_H
#define VSMSGDEFS_JAVA_H
enum VSMSGDEFS_JAVA {
    // Incomplete header in Java class file
    JAVA_CLASS_INCOMPLETE_HEADER_RC = -4170,
    // Invalid magic number for Java class file
    JAVA_CLASS_BAD_MAGIC_NUMBER_RC = -4171,
    // Unsupported Java class file version
    JAVA_CLASS_UNSUPPORTED_VERSION_RC = -4172,
    // Java class constant pool contains unrecognized type
    JAVA_CLASS_UNKNOWN_CONSTANT_TYPE_RC = -4173,
    // Java class attribute length mismatch
    JAVA_CLASS_ATTRIBUTE_LENGTH_MISMATCH_RC = -4174,
    // Could not locate Java source file
    JAVA_CLASS_SOURCE_NOT_FOUND_RC = -4175,
    // Invalid index into Java class constant pool
    JAVA_CLASS_INVALID_CONSTANT_INDEX_RC = -4176,
    // Could not find string in Java class constant pool
    JAVA_CLASS_STRING_NOT_FOUND_RC = -4177,
    // Incomplete header in Java archive file
    JAVA_JAR_INCOMPLETE_HEADER_RC = -4178,
    // Invalid magic number for Java archive file
    JAVA_JAR_BAD_MAGIC_NUMBER_RC = -4179,
    // Unsupported Java archive file version
    JAVA_JAR_UNSUPPORTED_VERSION_RC = -4180,
    // Error decompressing contents of Java archive file
    JAVA_JAR_DECOMPRESS_ERROR_RC = -4181,
    // Corrupt header in Java archive file
    JAVA_JAR_CORRUPT_HEADER_RC = -4182,
};
#endif

#ifndef VSMSGDEFS_OBJECT_H
#define VSMSGDEFS_OBJECT_H
enum VSMSGDEFS_OBJECT {
    // Incomplete header in object file
    OBJECT_FILE_INCOMPLETE_HEADER_RC = -4185,
    // Invalid magic number for object file
    OBJECT_FILE_BAD_MAGIC_NUMBER_RC = -4186,
    // Unrecognized object file type
    OBJECT_FILE_UNRECOGNIZED_RC = -4187,
    // Object file has no debug information
    OBJECT_FILE_NO_DEBUG_RC = -4188,
};
#endif

#ifndef VSMSGDEFS_METADATA_H
#define VSMSGDEFS_METADATA_H
enum VSMSGDEFS_METADATA {
    // C# library parsing is not supported on Unix
    METADATA_NOT_SUPPORTED_ON_UNIX_RC = -4190,
    // Could not open metadata DLL instance
    METADATA_CAN_NOT_CREATE_INSTANCE_RC = -4191,
    // Could not import from metadata DLL
    METADATA_CAN_NOT_CREATE_IMPORTER_RC = -4192,
};
#endif

#ifndef VSMSGDEFS_VSBUILD_H
#define VSMSGDEFS_VSBUILD_H
enum VSMSGDEFS_VSBUILD {
    // Usage: vsbuild [WorkspaceName] [ProjectName] [-t TargetName] [Options]
    // 
    //    WorkspaceName     Name of workspace. Not required if there are no
    //                      dependencies and ProjectName is specified.
    //    ProjectName       Project file that is part of the workspace.
    //                      Defaults to the current project.
    //    -t <TargetName>   Target name is the name of the target to run.
    //    -c <ConfigName>   Configuration   name is the name of the configuration to build.
    //    -b <BufferName>   Buffer name is the name of the current buffer in the editor.
    //    -d                Do not build, display dependencies.
    //    -v or -verbose    Verbose mode.
    //    -verbosefiles     Verbose mode + dump contents of temporary list files.
    //    -verboseenv       Verbose mode + dump environment variables set.
    //    -quiet            Quiet mode.
    //    -nodep            Do not process project dependencies.
    //    -beep             Beep at the end of a build to signal success or failure.
    //    -time             Display time elapsed during build.
    //    -log              Output build information to a per-project log file.
    //    -threaddeps       Build dependent projects on separate threads.
    //    -threadcompiles   Run source file compiles in parallel (4 threads).
    //    -wc <Wildcards>   Semi-colon delimited list of wildcards.
    //    -execute <CmdLine>
    //                      This option must be last.
    //                      Executes the target given and if successful, executes the
    //                      <CmdLine> given.
    //    -execAsTarget <CmdLine>
    //                      This option must be last.
    //                      Executes the command given as if it were a target.
    //    -doNotCreateObjectDir
    //                      Do not create object directories.
    // Example
    //     vsbuild project.vpj -t Build
    //          Compile files in the project which are out-of-date.
    // 
    //     vsbuild project.vpj -t Rebuild
    //          Recompiles all files in the project.
    // 
    //     vsbuild project.vpj -t "Make Jar"
    //          Compile Java files in the project which are out-of-date and
    //          update the project jar file.
    // 
    //     vsbuild project.vpj -t "Javadoc All"
    //          Update HTML documentation for all Java files in the project.
    // 
    VSBUILDRC_USAGE = -4200,
    // {0}Cannot open file '{1}'
    VSBUILDRC_CANNOT_OPEN_FILE_2ARG = -4201,
    // {0}Could not read file '{1}'
    VSBUILDRC_ERROR_READ_FILE_2ARG = -4202,
    // {0}Cannot use %M option when using vsbuild
    VSBUILDRC_CANNOT_USE_M_OPTION_1ARG = -4203,
    // {0}Cannot use %C option when using vsbuild
    VSBUILDRC_CANNOT_USE_C_OPTION_1ARG = -4204,
    // {0}Cannot use %L option when using vsbuild
    VSBUILDRC_CANNOT_USE_L_OPTION_1ARG = -4205,
    // {0}Cannot use %NNN option when using vsbuild
    VSBUILDRC_CANNOT_USE_NNN_OPTION_1ARG = -4206,
    // {0}Warning: %{filter} option does not currently support files in associated project files
    VSBUILDRC_CANNOT_USE_FILTER_OPTION_1ARG = -4207,
    // {0}Workspace file '{1}' not found
    VSBUILDRC_WORKSPACE_FILE_NOT_FOUND_1ARG = -4208,
    // {0}Workspace history file '{1}' not found
    VSBUILDRC_HISTORY_FILE_NOT_FOUND_2ARG = -4209,
    // {0}Project file '{1} not found
    VSBUILDRC_PROJECT_FILE_NOT_FOUND_2ARG = -4210,
    // {0}No dependencies for {1}
    VSBUILDRC_NO_DEPENDENCIES_2ARG = -4211,
    // {0}'{1}' depends on '{2}'
    VSBUILDRC_DEPENDS_ON_3ARG = -4212,
    // {0}Command '{1}' not defined in project file '{2}'
    VSBUILDRC_COMMAND_NOT_DEFINED_IN_PROJECT_3ARG = -4213,
    // {0}Could not change to directory '{1}
    VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG = -4214,
    // {0}Changed to directory '{1}'
    VSBUILDRC_CHANGED_TO_DIRECTORY_2ARG = -4215,
    // {0}No build command for project '{1}'
    VSBUILDRC_NO_BUILD_COMMAND_FOR_PROJECT_2ARG = -4216,
    // {0}Program '{1}' not found
    VSBUILDRC_PROGRAM_NOT_FOUND_2ARG = -4217,
    // {0}All files are up-to-date
    VSBUILDRC_ALL_FILES_HAVE_BEEN_COMPILED_1ARG = -4218,
    // {0}Build stopped. {1} returned {2}
    VSBUILDRC_STOP_WITH_ERROR_3ARG = -4219,
    // {0}No current project
    VSBUILDRC_NO_CURRENT_PROJECT_1ARG = -4220,
    // {0}jar command for project '{1}' must specify 'f' option
    VSBUILDRC_JAR_COMMAND_MUST_SPECIFY_F_OPTION_2ARG = -4221,
    // {0}jar command for project '{1}' must specify 'c' or 'u' option
    VSBUILDRC_JAR_COMMAND_MUST_SPECIFY_C_OR_U_OPTION_2ARG = -4222,
    // {0}Unknown option '{1}'
    VSBUILDRC_UNKNOWN_OPTION_2ARG = -4223,
    // {0}Unable to open temp list file '{1}'
    VSBUILDRC_UNABLE_TO_OPEN_TEMP_LIST_FILE_2ARG = -4224,
    // {0}Out of disk space writing to temp list file '{1}'
    VSBUILDRC_OUT_OF_DISK_SPACE_WRITING_TO_TEMP_LIST_FILE_2ARG = -4225,
    // {0}Unable to initialize dependency analyzer.  Check disk space and permissions for the object directory.
    VSBUILDRC_CANNOT_INIT_DEPENDENCY_DATABASE_1ARG = -4226,
    // {0}Cannot specify vsbuild as build tool without specifying an operation
    VSBUILDRC_INFINITE_COMMAND_RECURSION_1ARG = -4227,
    // {0}*** Errors occurred during this build ***
    VSBUILDRC_ERRORS_OCCURRED_1ARG = -4228,
    // {0}Build successful
    VSBUILDRC_BUILD_SUCCESSFUL_1ARG = -4229,
    // {0}---------- Build Project: '{1}' - '{2}' ----------
    VSBUILDRC_BUILDING_PROJECT_3ARG = -4230,
    // {0}---------- Rebuild Project: '{1}' - '{2}' ----------
    VSBUILDRC_REBUILDING_PROJECT_3ARG = -4231,
    // {0}---------- Jar Project: '{1}' - '{2}' ----------
    VSBUILDRC_JARRING_PROJECT_3ARG = -4232,
    // {0}---------- Javadoc Project: '{1}' - '{2}' ----------
    VSBUILDRC_JAVADOCING_PROJECT_3ARG = -4233,
    // {0}No files in project
    VSBUILDRC_NO_FILES_IN_PROJECT_1ARG = -4234,
    // {0}Dependency database not found.  Rebuilding...
    VSBUILDRC_DEPENDENCY_DATABASE_NOT_FOUND_1ARG = -4235,
    // {0}Dependency database outdated.  Rebuilding...
    VSBUILDRC_DEPENDENCY_DATABASE_OUTDATED_1ARG = -4236,
    // {0}Nothing to link
    VSBUILDRC_NOTHING_TO_LINK_1ARG = -4237,
    // {0}Infinite recursion detected while replacing '{1}'
    VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG = -4238,
    // {0}No configuration specified and no active configuration found in history file.
    VSBUILDRC_NO_CONFIG_SPECIFIED_1ARG = -4239,
    // {0}Configuration '{1}' not found in project file '{2}'
    VSBUILDRC_CONFIG_NOT_FOUND_3ARG = -4240,
    // {0}File '{1}' not found
    VSBUILDRC_FILE_NOT_FOUND_2ARG = -4241,
    // {0}Could not setup environment
    VSBUILDRC_ERROR_SETTING_UP_ENVIRONMENT_1ARG = -4242,
    // {0}---------- Clean Project: '{1}' - '{2}' ----------
    VSBUILDRC_CLEANING_PROJECT_3ARG = -4243,
    // {0}Unable to remove file '{1}'
    VSBUILDRC_CANNOT_REMOVE_FILE_2ARG = -4244,
    // {0}Compile/Link command change detected.  Some files may be rebuilt.
    VSBUILDRC_CPP_COMMAND_CHANGE_DETECTED_1ARG = -4245,
    // {0}Configuration or command change detected.  All files will be rebuilt.
    VSBUILDRC_JAVA_CONFIG_OR_COMMAND_CHANGE_DETECTED_1ARG = -4246,
    // {0}File '{1}' is an invalid format and cannot be read.
    VSBUILDRC_INVALID_FILE_FORMAT_2ARG = -4247,
    // {0}Target must be specified for dependency that is internal to the project.
    VSBUILDRC_TARGET_REQUIRED_1ARG = -4248,
    // {0}Target '{1}' not found in project file '{2}' configuration '{3}'
    VSBUILDRC_TARGET_NOT_FOUND_4ARG = -4249,
    // {0}Cannot read dependency database.
    VSBUILDRC_CANNOT_READ_DEPENDENCY_DATABASE_1ARG = -4250,
    // {0}Cannot build with ant because ANT_HOME and/or JAVA_HOME are not set.
    VSBUILDRC_ANT_HOME_NOT_FOUND_1ARG = -4251,
    // {0}Linkable object count change detected.  The project will be relinked.
    VSBUILDRC_CPP_OBJECT_COUNT_CHANGE_DETECTED_1ARG = -4252,
    // {0}vsbuild command can't change workspace, project, configuration, or target. Use CallTarget
    VSBUILDRC_VSBUILD_COMMAND_CANT_CHANGE_WORKSPACE_PROJECT_CONFIG_OR_TARGET_1ARG = -4253,
    // {0}---------- '{1}' Project: '{2}' - '{3}' ----------
    VSBUILDRC_TARGET_PROJECT_4ARG = -4254,
    // {0}Invalid arguments: {1}
    VSBUILDRC_INVALID_ARGUMENT_2ARG = -4255,
    // {0}No rule found for file '{1}'
    VSBUILDRC_NO_COMPILE_RULE_FOUND_FOR_FILE_2ARG = -4256,
    // {0}File '{1}' written multiple times. Source file is probably specified in two different projects.
    VSBUILDRC_FILE_WRITTEN_TO_MULTIPLE_TIMES_2ARG = -4257,
    // {0}Database file '{1}' written multiple times. Need to make sure configurations have different output directories
    VSBUILDRC_DATABASE_WRITTEN_TO_MULTIPLE_TIMES_2ARG = -4258,
    // {0}Dependency from project '{1}'- '{2}' - '{3}' not found
    VSBUILDRC_DEPENCY_FROM_NOT_FOUND_4ARG=-4259,
};
#endif

#ifndef VSMSGDEFS_LICENSE_H
#define VSMSGDEFS_LICENSE_H
enum VSMSGDEFS_LICENSE {
    // Run the vsupdatw program as shown below (Start, Run) to transfer serial number and license information.
    // 
    // Usage:
    // 	vsupdatw old-exe-name new-exe-name
    // 
    // 	old-exe-name	Name of original executable to take license information from.
    // 	new-exe-name	Name of new executable to transfer license information to.
    VSLM_RUN_VSUPDATE_WIN_RC = -4300,
    // Run the vsupdate program as shown below to transfer serial number and license information.
    // 
    // Usage:
    // 	vsupdatw old-exe-name new-exe-name
    // 
    // 	old-exe-name	Name of original executable to take license information from.
    // 	new-exe-name	Name of new executable to transfer license information to.
    VSLM_RUN_VSUPDATE_OS2_RC = -4301,
    // Run the vsupdate program as shown below to transfer serial number and license information.
    // 
    // Usage:
    // 	vsupdate old-exe-name new-exe-name
    // 
    // 	old-exe-name	Name of original executable to take license information from.
    // 	new-exe-name	Name of new executable to transfer license information to.
    VSLM_RUN_VSUPDATE_UNIX_RC = -4302,
    // Run the vsupdate program as shown below to transfer serial number and license information.
    // 
    //    vsupdate  <old-libvsapi-name> <new-libvsapi-name>
    // 
    VSLM_RUN_VSUPDATE_UNIXDLL_RC = -4303,
    // The serial #{1} is not valid.
    // Please contact SlickEdit Support.
    VSLM_SERIAL_NUMBER_NOT_VALID_RC = -4304,
    // Unable to obtain a FLEXlm license to run {1}.
    // FLEXlm reports the following error:
    // 
    // 
    VSLM_UNABLE_TO_OBTAIN_FLEXLM_LICENSE_RC = -4305,
    // Error seeking to beginning of license file
    VSLM_ERROR_SEEKING_TO_BEGINNING_RC = -4306,
    // Error seeking to end of license file
    VSLM_ERROR_SEEKING_TO_END_RC = -4307,
    // Error writing to file '{1}'.  Check disk space.
    VSLM_ERROR_WRITING_TO_FILE_RC = -4308,
    // Error reading license file '{1}'
    VSLM_ERROR_READING_LICENSE_FILE_RC = -4309,
    // User '{1}' not found in '{2}'
    VSLM_USER_NOT_FOUND_RC = -4310,
    // Timeout opening or creating license file '{1}'.  Make sure your system administrator has given all users read/write access to this file and that this file exists.
    VSLM_ERROR_OPENING_OR_CREATING_RC = -4311,
    // Timeout opening license file '{1}'. Make sure your system administrator has given all users read access to this file and that this file exists.
    VSLM_ERROR_OPENING_RC = -4312,
    // The serial #{1} and license #{2} are not valid.
    // Please contact SlickEdit Support.
    VSLM_SERIAL_NUMBER_AND_LICENSE_NOT_VALID_RC = -4313,
    // Unable to create license manager directory.  Have your system administrator create the directory '{1}' and give all users access to this directory
    VSLM_UNABLE_TO_CREATE_LICENSE_MANAGER_DIR_RC = -4314,
    // User '{1}' is not authorized to run SlickEdit. Please consult your system administrator to have your user name added to the license file.
    // 
    VSLM_USER_NOT_AUTHORIZED_RC = -4315,
    // License limit of {1} users for serial #{2} in package <{4}> reached.  You may purchase additional licenses or wait until someone exits the editor.
    // 
    // To check how many users are running the editor, type the following command:
    // 
    //     type {3}
    // 
    // The total usage count is FirstLineCount+NoflinesInFile-1.
    // 
    // An abnormal exit from the editor will cause this count to be incorrect.  After an abnormal exit from the editor, that user should run the vsdelw program (Start, Run).
    // 
    // Using the vsdelw program to intentionally decrement the count below the actual usage count violates this program's license agreement.
    VSLM_LICENSE_LIMIT_REACHED_WIN_RC = -4316,
    // License limit of {1} users for serial #{2} in package <{4}> reached.  You may purchase additional licenses or wait until someone exits the editor.
    // 
    // To check how many users are running the editor, type the following command:
    // 
    //     type {3}
    // 
    // The total usage count is FirstLineCount+NoflinesInFile-1.
    // 
    // 
    // An abnormal exit from the editor will cause this count to be incorrect.  After an abnormal exit from the editor, that user should run the vsdel program.
    // 
    // Using the vsdel program to intentionally decrement the count below the actual usage count violates this program's license agreement.
    VSLM_LICENSE_LIMIT_REACHED_OS2_RC = -4317,
    // License limit of {1} users for serial #{2} reached.  You may purchase additional licenses or wait until someone exits the editor.
    // 
    // To check how many users are running the editor, type the following command:
    // 
    //     cat {3}
    // 
    // The total usage count is FirstLineCount+NoflinesInFile-1.
    // 
    // 
    // An abnormal exit from the editor will cause this count to be incorrect.  After an abnormal exit from the editor, that user should run the vsdel program.
    // 
    // Using the vsdel program to intentionally decrement the count below the actual usage count violates this program's license agreement.
    VSLM_LICENSE_LIMIT_REACHED_UNIX_RC = -4318,
    // Failed to open trial size file
    VSTRIAL_FAILED_TO_OPEN_TRIAL_SIZE_FILE_RC = -4319,
    // Error in trial size file
    VSTRIAL_ERROR_IN_TRIAL_SIZE_FILE_RC = -4320,
    // Failed to open trial executable
    VSTRIAL_FAILED_TO_OPEN_TRIAL_EXECUTABLE_RC = -4321,
    // Serial number and license information must be patched into the product.  This step is necessary to personalize your copy of the product and to receive prompt technical support.
    // 
    // You will need your license code that was provided to you.  If you ordered online you may receive the code separately via email.  Call SlickEdit support at 800-934-3348 or 919.473.0070 if you have lost your code.  If you choose not to perform this step at this time you will be prompted with this message each time SlickEdit is invoked.
    // 
    // Update serial number and license information now?
    VSTRIAL_PATCH_SERIAL_NUMBER_AND_LICENSE_RC = -4322,
    // Failed to execute {1}.  Could be out of memory.
    // 
    // Exit SlickEdit and run {2}vssetlnw.exe to patch serial number and license information.  Have your license code ready.
    VSTRIAL_FAILED_TO_EXECUTE_RC = -4323,
    // Version 12.0
    // 
    // This program is used to remove a user from the {1} file.  This is necessary only if a user exits the editor abnormally.
    // 
    // Usage:
    // 
    // vsdel <path>/{1} user [-s section [-s section ...]]
    // 
    // 	path	Path to license file '{1}'.
    // 	user	Name of user to delete from license file.
    // 	section	Optional.  Name of a package section to delete user from (e.g. 'STD').
    // 		If not given, then user is deleted from all sections.
    // 
    // Using the vsdel program to intentionally delete a user who is still using SlickEdit violates this program's license agreement.
    // 
    VSDEL_HELP_UNIX_RC = -4324,
    // Version 12.0
    // 
    // This program is used to remove a user from the {1} file.  This is necessary only if a user exits the editor abnormally.
    // 
    // Usage:
    // 
    //     vsdelw <path>\{1} [user] [-s section [-s section ...]]
    // 
    // 	path	Path to license file '{1}'.
    // 	user	Name of user to delete from license file.  User name comes from the
    // 		VSUSER environment variable or Windows login.  If the user name is
    // 		not given, then global license count is decremented.
    // 	section	Optional.  Name of a package section to delete user from (e.g. 'STD').
    // 		If not given, then user is deleted from all sections.
    // 
    // Using the vsdelw program to intentionally decrement the usage count below the actual usage count violates this program's license agreement.
    // 
    VSDELW_HELP_WIN_RC = -4325,
    // Demo version has expired
    VSLM_DEMO_EXPIRED_RC = -4326,
    // 
    DEMO_EXPIRATION_DATE_RC = -4327,
    // Error in trial
    VSTRIAL_ERROR_IN_TRIAL_RC = -4328,
    // The package <{1}> is not valid.
    // Please contact SlickEdit Support.
    VSLM_PACKAGE_NOT_VALID_RC = -4329,
    // The serial #{1} does not match the license for package <{2}> ({3}).
    // Please contact SlickEdit Support.
    VSLM_SERIAL_AND_LICENSE_MISMATCH_RC = -4330,
    // The package is invalid or missing ({1}).
    // Please contact SlickEdit Support.
    VSLM_INVALID_PACKAGE_RC = -4331,
    // Too many packages.
    // Please contact SlickEdit Support.
    VSLM_TOO_MANY_PACKAGES_RC = -4332,
    // The following packages could not be licensed because the user limit has been reached, or the user is not licensed for these packages.  Licensing can also fail when the license file is set to read only and/or a user's name does not appear in the list of licensed users.  Read the "License Manager" section of the manual for more information on the format of the license file.
    VSLM_PACKAGES_NOT_LICENSED_RC = -4333,
    // User '{1}' not found in '{2}' for the following packages: 
    VSLM_USER_NOT_FOUND2_RC = -4334,
    // You have not installed a license key for the following packages.  This can happen when you have package sections in your license file that you are not/no longer licensed for.  The system administrator can use the '{1}' utility to add support for additional packages.
    VSLM_PACKAGES_NOT_LICENSED2_RC = -4335,
    // The package <{1}> is invalid.
    // 
    VSLM_INVALID_PACKAGE2_RC = -4336,
    // The registration macro was not found. Call SlickEdit Support.
    VSREG_MACRO_NOT_FOUND_RC = -4337,
    // Error opening registration data file
    VSREG_ERROR_OPENING_DATA_FILE_RC = -4338,
    // Error reading registration data file
    VSREG_ERROR_READING_DATA_FILE_RC = -4339,
    // Invalid or unsupported registration data version
    VSREG_INVALID_DATA_VERSION_RC = -4340,
    // Invalid trial. Please contact SlickEdit Support.
    VSTRIAL_INVALID_TRIAL_RC = -4341,
    // This trial will expire on {1}
    VSTRIAL_EXPIRING_RC = -4342,
    // The trial registration macro was not found. Call SlickEdit Support.
    VSTRIAL_MACRO_NOT_FOUND_RC = -4343,
    // This trial has expired. SlickEdit will now exit.
    VSTRIAL_TRIAL_EXPIRED_RC = -4344,
    // Thank you for trying {0}.
    // 
    // This trial will expire soon. If you would like to purchase, please contact our sales department.
    VSTRIAL_EXPIRING2_RC = -4345,
    // This trial has expired. SlickEdit Core will now be disabled.
    VSTRIAL_ECLIPSE_TRIAL_EXPIRED_RC = -4346,
    // Unable to contact registration server (status = %rc%).
    // <p>
    // If you are accessing the internet through a proxy, use the "Proxy Settings..." button to configure your proxy settings. Some more sophisticated proxies that require a login are not currently supported. If you are behind one of these types of proxies, then please do one of the following:
    // <p>
    // Paste the following link into the Address bar of your web browser. You will be emailed back instructions to activate your trial license.
    // <p>
    // %link%
    // <p>
    VSTRIAL_ERROR_CONTACTING_REGISTRATION_SERVER_RC = -4347,
    // To purchase {1}, please contact SlickEdit Sales at 800 934-3348 or +1 919.473.0070 purchase online at www.slickedit.com.
    VSRC_DEMO_NAG_MESSAGE = -4348,
    // Unable to obtain license using license file(s):
    // {2}
    // 
    // FLEXlm reports the following error:
    // 
    // 
    VSLM_UNABLE_TO_OBTAIN_FLEXLM_LICENSE_FROM_FILE_RC = -4349,
    // Unable to obtain license using license file(s).
    VSLM_UNABLE_TO_OBTAIN_LICENSE_RC = -4350,
    // Unable to return license to license server:
    // {2}
    // Error:
    // 
    VSLM_UNABLE_TO_RETURN_LICENSE_RC = -4351,
    // Unable to write borrow license.
    // File:
    // 
    // 
    VSLM_UNABLE_TO_WRITE_BORROW_LICENSE_RC = -4352,
    // Unable to checkout borrow license.
    // Error:
    // 
    VSLM_UNABLE_TO_BORROW_LICENSE_RC = -4353,
    // Return license failed.
    // Checkout license from server {2}?
    VSLM_RETURN_FAILED_CHECKOUT_LICENSE_RC = -4354,
    // Borrows are not allowed with this license.
    VSLM_BORROW_INCORRECT_LICENSE_RC = -4355,
    // Unable to borrow license from server.
    // Error:
    // 
    VSLM_BORROW_FAILURE_RC = -4356,
};
#endif

#ifndef VSMSGDEFS_VSEXECFROMFILE_H
#define VSMSGDEFS_VSEXECFROMFILE_H
enum VSMSGDEFS_VSEXECFROMFILE {
    // Usage: vsexecfromfile [-d] <filename>
    // 
    // Where <filename> contains a one line command line to be executed.
    // Specify -d to erase the file after executing is completed.
    RCVSEXECFROMFILE_USAGE = -4500,
    // Unable to open '{1}'.  Make sure the file exists
    RCVSEXECFROMFILE_UNABLE_TO_OPEN_FILE = -4501,
    // Unable to read line from '{1}'.  Make sure file has a command line
    RCVSEXECFROMFILE_ERROR_READING_COMMAND_LINE = -4502,
    // Executing
    RCVSEXECFROMFILE_EXECUTING = -4503,
    // Executing
    RCVSEXECFROMFILE_ARGUMENT_LIST_TOO_BIG = -4504,
    // Command-interpreter file has invalid format and is not executable
    RCVSEXECFROMFILE_INVALID_EXECUTABLE = -4505,
    // Command interpreter cannot be found.
    RCVSEXECFROMFILE_COMMAND_INTERPRETER_NOT_FOUND = -4506,
    // Program not found. Command: {1}
    RCVSEXECFROMFILE_PROGRAM_NOT_FOUND = -4507,
    // Not enough memory is available to execute command; or available memory has been corrupted; or invalid block exists, indicating that process making call was not allocated properly.
    RCVSEXECFROMFILE_NOT_ENOUGH_MEMORY = -4508,
    // Error executing command
    RCVSEXECFROMFILE_ERROR_EXECUTING_COMMAND = -4509,
};
#endif

#ifndef VSMSGDEFS_CODEHELP_H
#define VSMSGDEFS_CODEHELP_H
enum  VSMSGDEFS_CODEHELP {
    // Context not valid
    VSCODEHELPRC_CONTEXT_NOT_VALID = -4601,
    // The cursor is not in a function argument list
    VSCODEHELPRC_NOT_IN_ARGUMENT_LIST = -4602,
    // No help found for this function: '{1}'
    VSCODEHELPRC_NO_HELP_FOR_FUNCTION = -4603,
    // No symbols found matching '{1}'
    VSCODEHELPRC_NO_SYMBOLS_FOUND = -4604,
    // The expression ({1}) is too complex
    VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX = -4605,
    // Unable to evaluate type expression ({1})
    VSCODEHELPRC_UNABLE_TO_EVALUATE_CONTEXT = -4606,
    // Attempt to use operator '{1}', but variable '{2}' is a pointer
    VSCODEHELPRC_DOT_FOR_POINTER = -4607,
    // Attempt to use operator '{1}', but variable '{2}' is not a pointer
    VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER = -4608,
    // Unable to evaluate 'new' expression ({1})
    VSCODEHELPRC_INVALID_NEW_EXPRESSION = -4609,
    // Unable to evaluate expression with mismatched parenthesis
    VSCODEHELPRC_PARENTHESIS_MISMATCH = -4610,
    // Unable to evaluate expression with mismatched brackets
    VSCODEHELPRC_BRACKETS_MISMATCH = -4611,
    // Attempt to use operator '{1}', but variable '{2}' is a pointer to pointer
    VSCODEHELPRC_DASHGREATER_FOR_PTR_TO_POINTER = -4612,
    // Attempt to use subscript '[]', but variable '{1}' is not an array type
    VSCODEHELPRC_SUBSCRIPT_BUT_NOT_ARRAY_TYPE = -4613,
    // Unable to determine type due to overloaded symbol '{1}'
    VSCODEHELPRC_OVERLOADED_RETURN_TYPE = -4614,
    // Template parameters found, but class '{1}' is not a template
    VSCODEHELPRC_NOT_A_TEMPLATE_CLASS = -4615,
    // Unable to locate definition of expression type: '{1}'
    VSCODEHELPRC_RETURN_TYPE_NOT_FOUND = -4616,
    // Unable to evaluate expression with mismatched template arguments
    VSCODEHELPRC_TEMPLATE_ARGS_MISMATCH = -4617,
    // Symbol {1} is declared as a simple type '{2}'
    VSCODEHELPRC_BUILTIN_TYPE = -4618,
    // No labels defined in current function or procedure
    VSCODEHELPRC_NO_LABELS_DEFINED = -4619,
    // Attempt to use operator '{1}', but variable '{2}' is an array
    VSCODEHELPRC_DOT_FOR_ARRAY = -4620,
    // Auto list parameters is not supported for this language
    VSCODEHELPRC_LIST_PARAMS_NOT_SUPPORTED = -4621,
    // Function returns void: '{1}'
    VSCODEHELPRC_RETURN_TYPE_IS_VOID = -4622,
    // Auto list members timed out
    VSCODEHELPRC_LIST_MEMBERS_TIMEOUT = -4623,
    // Auto parameter information timed out
    VSCODEHELPRC_FUNCTION_HELP_TIMEOUT = -4624,
    // Auto list members found maximum number of symbols
    VSCODEHELPRC_LIST_MEMBERS_LIMITED = -4623,
    // File is too large for this feature, increase {1}
    VSCODEHELPRC_FILE_TOO_LARGE = -4624,
};
#endif

#ifndef VSMSGDEFS_SLICKC_COMPILE_H
#define VSMSGDEFS_SLICKC_COMPILE_H
enum VSMSGDEFS_SLICKC_COMPILER {
    // {1} {2} {3}: {4}:
    SCCOMPERR_FILEPOS = -5000,
    // "{1}" {2} {3}: {4}:
    SCCOMPERR_SPACEFILEPOS = -5001,
    // Error
    SCCOMPERR_ERROR = -5002,
    // Warning
    SCCOMPERR_WARNING = -5003,
    // Fatal error
    SCCOMPERR_FATALERROR = -5004,
    // Preprocessing variable not initialized.  Initialize variable with #define,#undef statement or /d,/u invocation option
    SCCOMPERR_DEFINE_NOT_INITIALIZED = -5005,
    // Identifier too long.  Identifier truncated
    SCCOMPERR_ID_TOO_LONG = -5006,
    // Comment not terminated
    SCCOMPERR_COMMENT_NOT_TERMINATED = -5006,
    // Illegal character
    SCCOMPERR_ILLEGAL_CHARACTER = -5007,
    // String not terminated
    SCCOMPERR_STRING_NOT_TERMINATED = -5008,
    // Invalid string token
    SCCOMPERR_INVALID_STRING_TOKEN = -5009,
    // Unrecognized escape sequence
    SCCOMPERR_UNRECOGNIZED_ESCAPE_SEQUENCE = -5010,
    // Empty character literal
    SCCOMPERR_EMPTY_CHARACTER_LITERAL = -5011,
    // Single-line comment or end-of-line expected
    SCCOMPERR_SINGLE_LINE_COMMENT_OR_EOF_EXPECTED = -5012,
    // Unrecognized preprocessor directive
    SCCOMPERR_UNRECOGNIZED_PREPROCESSOR_DIRECTIVE = -5013,
    // #IF preprocessing nested too deep
    SCCOMPERR_PREPROCESSING_NESTED_TOO_DEEP = -5014,
    // Unexpected preprocessor directive
    SCCOMPERR_UNEXPECTED_PREPROCESSOR_DIRECTIVE = -5015,
    // ) expected
    SCCOMPERR_RIGHT_PAREN_EXPECTED = -5016,
    // Invalid preprocessor expression
    SCCOMPERR_INVALID_PREPROCESSOR_EXPRESSION = -5017,
    // #error %5
    SCCOMPERR_ERROR_DIRECTIVE = -5018,
    // Identifier expected
    SCCOMPERR_IDENTIFIER_EXPECTED = -5019,
};
#endif

#ifndef VSMSGDEFS_XMLCFG_H
#define VSMSGDEFS_XMLCFG_H
enum VSMSGDEFS_XMLCFG {
    // Expecting root element name in DOCTYPE
    VSRC_XMLCFG_EXPECTING_ROOT_ELEMENT_NAME = -5400,
    // Expecting quoted system id
    VSRC_XMLCFG_EXPECTING_QUOTED_SYSTEM_ID = -5401,
    // String not terminated
    VSRC_XMLCFG_STRING_NOT_TERMINATED = -5402,
    // 
    VSRC_XMLCFG_NOT_USED1 = -5403,
    // '{4}' start tag not terminated
    VSRC_XMLCFG_START_TAG_NOT_TERMINATED = -5404,
    // Comment not terminated
    VSRC_XMLCFG_COMMENT_NOT_TERMINATED = -5405,
    // Invalid characters in comment
    VSRC_XMLCFG_INVALID_CHARACTERS_IN_COMMENT = -5406,
    // Expecting an element name
    VSRC_XMLCFG_EXPECTING_AN_ELEMENT_NAME = -5407,
    // Expecting attribute name
    VSRC_XMLCFG_EXPECTING_ATTRIBUTE_NAME = -5408,
    // Expecting '=' after attribute name
    VSRC_XMLCFG_EXPECTING_EQUAL_AFTER_ATTRIBUTE_NAME = -5409,
    // Attribute value must be quoted
    VSRC_XMLCFG_ATTRIBUTE_VALUE_MUST_BE_QUOTED = -5410,
    // Processing instruction not terminated
    VSRC_XMLCFG_PROCESSING_INSTRUCTION_NOT_TERMINATED = -5411,
    // The input ended before all tags were terminated.
    VSRC_XMLCFG_INPUT_ENDED_BEFORE_ALL_TAGS_WERE_TERMINATED = -5412,
    // Expecting quoted public id
    VSRC_XMLCFG_EXPECTING_QUOTED_PUBLIC_ID = -5413,
    // DOCTYPE Internal subset not terminated
    VSRC_XMLCFG_DOCTYPE_INTERNAL_SUBSET_NOT_TERMINATED = -5414,
    // Invalid document structure
    VSRC_XMLCFG_INVALID_DOCUMENT_STRUCTURE = -5414,
    // Expecting SYSTEM or PUBLIC id
    VSRC_XMLCFG_EXPECTING_SYSTEM_OR_PUBLIC_ID = -5416,
    // Expecting processor name
    VSRC_XMLCFG_EXPECTING_PROCESSOR_NAME = -5417,
    // File already open
    VSRC_XMLCFG_FILE_ALREADY_OPEN = -5418,
    // ?xml declaration not terminated
    VSRC_XMLCFG_XML_DECLARATION_NOT_TERMIANTED = -5419,
    // Expecting comment or CDATA
    VSRC_XMLCFG_EXPECTING_COMMENT_OR_CDATA = -5420,
    // CDATA not terminated
    VSRC_XMLCFG_CDATA_NOT_TERMINATED = -5421,
    // Attribute not found
    VSRC_XMLCFG_ATTRIBUTE_NOT_FOUND = -5422,
    // Name not found
    VSRC_XMLCFG_NAME_NOT_FOUND = -5423,
    // Cannot add child node to an attribute node
    VSRC_XMLCFG_CANT_ADD_CHILD_NODE_TO_ATTRIBUTE_NODE = -5424,
    // Attributes must be the first children of element nodes
    VSRC_XMLCFG_ATTRIBUTES_MUST_BE_THE_FIRST_CHILDREN = -5425,
    // Cannot add sibling to root node
    VSRC_XMLCFG_CANT_ADD_SIBLING_TO_ROOT_NODE = -5426,
    // Unable to initialize XML system ({2}) : {1}
    VSRC_XML_SYSTEM_FAILED_TO_INITIALIZE = -5427,
    // Unexpected parsing error: {1}
    VSRC_XML_UNEXPECTED_PARSING_ERROR1 = -5428,
    // Parsing error ({2}): {1}
    VSRC_XML_GENERAL_PARSING_ERROR = -5429,
    // Unexpected parsing error.
    VSRC_XML_UNEXPECTED_PARSING_ERROR = -5430,
    // Internal XML error.  Proc index not found for _mapxml_find_system_file
    VSRC_XML_INTERNAL_ERROR_PROC_INDEX_NOT_FOUND = -5431,
    // No children copied
    VSRC_XMLCFG_NO_CHILDREN_COPIED = -5432,
    // Invalid XMLCFG handle
    VSRC_XMLCFG_INVALID_HANDLE = -5433,
    // Invalid XMLCFG node index
    VSRC_XMLCFG_INVALID_NODE_INDEX = -5434,
    // Too many end tags
    VSRC_XMLCFG_TOO_MANY_END_TAGS = -5435,
};
#endif

#ifndef VSMSGDEFS_DEBUGGER_H
#define VSMSGDEFS_DEBUGGER_H
enum VSMSGDEFS_DEBUGGER {
    // The debugger has not been initialized
    DEBUG_NOT_INITIALIZED_RC = -5500,
    // Breakpoint not found
    DEBUG_BREAKPOINT_NOT_FOUND_RC = -5501,
    // This operation is allowed only when the thread is suspended
    DEBUG_THREAD_NOT_SUSPENDED_RC = -5502,
    // Invalid JDWP ID
    DEBUG_INVALID_ID_RC = -5503,
    // Index of debugger item is out of range or invalid
    DEBUG_INVALID_INDEX_RC = -5504,
    // Conditional breakpoints are not yet supported
    DEBUG_BREAKPOINT_CONDITION_UNSUPPORTED_RC = -5505,
    // Waiting for thread(s) to suspend
    DEBUG_THREAD_WAITING_FOR_SUSPEND_RC = -5506,
    // Could not find specified thread
    DEBUG_THREAD_NOT_FOUND_RC = -5507,
    // Could not find specified class
    DEBUG_CLASS_NOT_FOUND_RC = -5508,
    // Could not find specified function
    DEBUG_FUNCTION_NOT_FOUND_RC = -5509,
    // Could not find specified variable
    DEBUG_FIELD_NOT_FOUND_RC = -5510,
    // Can not remove an enabled breakpoint
    DEBUG_BREAKPOINT_NOT_DISABLED_RC = -5511,
    // Breakpoint already exists at this location
    DEBUG_BREAKPOINT_ALREADY_EXISTS_RC = -5512,
    // Program finished executing
    DEBUG_PROGRAM_FINISHED_RC = -5513,
    // Could not set breakpoint on specified line
    DEBUG_BREAKPOINT_LINE_NOT_FOUND_RC = -5514,
    // Breakpoints are not allowed in this context
    DEBUG_BREAKPOINT_NOT_ALLOWED_RC = -5515,
    // Can not set watch on specified symbol
    DEBUG_WATCH_NOT_ALLOWED_RC = -5516,
    // Current function was not compiled with debug
    DEBUG_NO_DEBUG_INFORMATION_RC = -5517,
    // Exception not found
    DEBUG_EXCEPTION_NOT_FOUND_RC = -5518,
    // Thread has no stack frames
    DEBUG_THREAD_NO_FRAMES_RC = -5519,
    // This expression is already being watched
    DEBUG_WATCH_ALREADY_EXISTS_RC = -5520,
    // There is no current thread
    DEBUG_NO_CURRENT_THREAD_RC = -5521,
    // There are no class members in this scope
    DEBUG_NO_MEMBERS_RC = -5522,
    // Could not find specified disassembly instruction
    DEBUG_INSTRUCTION_NOT_FOUND_RC = -5523,
    // Could not find specified file
    DEBUG_FILE_NOT_FOUND_RC = -5524,
    // Requested feature is not implemented for this debugger
    DEBUG_FEATURE_NOT_IMPLEMENTED_RC = -5525,
    // Invalid debugging session ID
    DEBUG_INVALID_SESSION_ID_RC = -5526,
    // Expecting a watchpoint, not a breakpoint
    DEBUG_NOT_A_WATCHPOINT_RC = -5527,
    // Unrecognized breakpoint type
    DEBUG_INVALID_BREAKPOINT_TYPE_RC = -5528,
    // Invalid watchpoint condition
    DEBUG_INVALID_WATCHPOINT_CONDITION_RC = -5529,
    // One or more breakpoints could not be enabled on startup and will be disabled
    DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC = -5530,
    // The requested feature is no longer available.
    DEBUG_FEATURE_REMOVED_RC = -5531,
    // This operation is not allowed when inspecting a core file
    DEBUG_CAN_NOT_RESUME_CORE_FILE_RC = -5532,
    // Error moving instruction pointer
    DEBUG_ERROR_SETTING_INSTRUCTION_POINTER_RC = -5533,
    // Can not move instruction pointer to specified line
    DEBUG_INVALID_LINE_FOR_INSTRUCTION_POINTER_RC = -5534,
    // Missing ':' in conditional expression
    DEBUG_EXPR_EXPECTING_COLON_RC = -5550,
    // Error parsing expression
    DEBUG_EXPR_GENERAL_ERROR_RC = -5551,
    // Expression contains an invalid operator
    DEBUG_EXPR_INVALID_OPERATOR_RC = -5552,
    // Expecting closing parenthesis
    DEBUG_EXPR_EXPECTING_CLOSE_PAREN_RC = -5553,
    // Attempt to divide by zero in expression
    DEBUG_EXPR_DIVIDE_BY_ZERO_RC = -5554,
    // Expecting ',' or ')' in function call expression
    DEBUG_EXPR_EXPECTING_COMMA_RC = -5555,
    // Expecting closing bracket
    DEBUG_EXPR_EXPECTING_CLOSE_BRACKET_RC = -5556,
    // Invalid condition in ?: expression
    DEBUG_EXPR_INVALID_CONDITION_RC = -5557,
    // Can not cast a void expression
    DEBUG_EXPR_CANNOT_CAST_VOID_RC = -5558,
    // Can not cast a boolean to another type
    DEBUG_EXPR_CANNOT_CAST_BOOLEAN_RC = -5559,
    // Can not cast a string to another type
    DEBUG_EXPR_CANNOT_CAST_STRING_RC = -5560,
    // Can not implicitly cast a class object to another type
    DEBUG_EXPR_CANNOT_CAST_OBJECT_RC = -5561,
    // A type is incompatible with the specified operator
    DEBUG_EXPR_INCOMPATIBLE_TYPE_RC = -5562,
    // Can not cast due to a possible loss of precision
    DEBUG_EXPR_LOSS_OF_PRECISION = -5563,
    // Left hand side of '.' operator is not a package, class or object
    DEBUG_EXPR_LHS_NOT_CLASS_RC = -5564,
    // Right hand side of '.' operator is not an identifier
    DEBUG_EXPR_RHS_INVALID_RC = -5565,
    // Can not cast a function to another type
    DEBUG_EXPR_CANNOT_CAST_FUNCTION_RC = -5566,
    // Can not cast an array to another type
    DEBUG_EXPR_CANNOT_CAST_ARRAY_RC = -5567,
    // Syntax error in watch expression
    DEBUG_EXPR_SYNTAX_ERROR_RC = -5568,
    // Can not find function context in this thread
    DEBUG_EXPR_CANNOT_FIND_CONTEXT_RC = -5569,
    // Symbol not found in this scope
    DEBUG_EXPR_SYMBOL_NOT_FOUND_RC = -5570,
    // Variable is not an array or string type
    DEBUG_EXPR_NOT_ARRAY_RC = -5572,
    // Array index is out of range
    DEBUG_EXPR_INVALID_ARRAY_INDEX_RC = -5573,
    // Identifier is not a function
    DEBUG_EXPR_NOT_FUNCTION_RC = -5574,
    // Can not call specified function
    DEBUG_EXPR_CANNOT_CALL_FUNCTION_RC = -5575,
    // An exception was thrown
    DEBUG_EXPR_EXCEPTION_RC = -5576,
    // Invalid argument
    DEBUG_EXPR_INVALID_ARGUMENT_RC = -5577,
    // Too many or too few arguments
    DEBUG_EXPR_WRONG_NUMBER_OF_ARGUMENTS_RC = -5578,
    // Could not find function matching arguments
    DEBUG_EXPR_ARGUMENT_MISMATCH_RC = -5579,
    // Identifier is not a class type
    DEBUG_EXPR_NOT_CLASS_RC = -5580,
    // Can not evaluate expression containing 'new'
    DEBUG_EXPR_CONTAINS_NEW_RC = -5581,
    // Expecting object type with 'instanceof' operator
    DEBUG_EXPR_EXPECTING_OBJECT_RC = -5582,
    // Too many levels of inheritance
    DEBUG_EXPR_TOO_MANY_LEVELS_RC = -5583,
    // Can not evaluate expression
    DEBUG_EXPR_CANNOT_EVALUATE_RC = -5584,
    // Can not use 'this' in a static method
    DEBUG_EXPR_STATIC_METHOD_RC = -5585,
    // Unsupported size for object ID
    DEBUG_JDWP_INVALID_SIZE_ARGUMENT_RC = -5600,
    // Attempted to read past end of packet
    DEBUG_JDWP_PAST_END_OF_PACKET_RC = -5601,
    // Invalid JDWP type tag constant
    DEBUG_JDWP_INVALID_TAG_CONSTANT_RC = -5602,
    // Unsupported JDWP data type
    DEBUG_JDWP_UNSUPPORTED_TAG_RC = -5603,
    // Did not receive correct handshake from virtual machine
    DEBUG_JDWP_INVALID_HANDSHAKE_RC = -5604,
    // The requested action is not supported by the virtual machine
    DEBUG_JDWP_UNSUPPORTED_BY_VIRTUAL_MACHINE_RC = -5605,
    // Packet header contains invalid packet size
    DEBUG_JDWP_INVALID_PACKET_SIZE_RC = -5606,
    // Packet contains invalid array size
    DEBUG_JDWP_INVALID_ARRAY_SIZE_RC = -5607,
    // Can not modify the value of expressions
    DEBUG_JDWP_ERROR_MODIFYING_VARIABLE_RC = -5608,
    // Watchpoints are not supported by the virtual machine
    DEBUG_JDWP_WATCHPOINT_NOT_SUPPORTED_RC = -5609,
    // The Java debugger does not support watchpoints on local variables
    DEBUG_JDWP_LOCAL_WATCHPOINT_NOT_SUPPORTED_RC = -5610,
    // Unsupported size for object ID
    DEBUG_MONO_INVALID_SIZE_ARGUMENT_RC = -5620,
    // Attempted to read past end of packet
    DEBUG_MONO_PAST_END_OF_PACKET_RC = -5621,
    // Invalid MONO type tag constant
    DEBUG_MONO_INVALID_TAG_CONSTANT_RC = -5622,
    // Unsupported MONO data type
    DEBUG_MONO_UNSUPPORTED_TAG_RC = -5623,
    // Did not receive correct handshake from virtual machine
    DEBUG_MONO_INVALID_HANDSHAKE_RC = -5624,
    // The requested action is not supported by the virtual machine
    DEBUG_MONO_UNSUPPORTED_BY_VIRTUAL_MACHINE_RC = -5625,
    // Packet header contains invalid packet size
    DEBUG_MONO_INVALID_PACKET_SIZE_RC = -5626,
    // Packet contains invalid array size
    DEBUG_MONO_INVALID_ARRAY_SIZE_RC = -5627,
    // Can not modify the value of expressions
    DEBUG_MONO_ERROR_MODIFYING_VARIABLE_RC = -5628,
    // Watchpoints are not supported by the virtual machine
    DEBUG_MONO_WATCHPOINT_NOT_SUPPORTED_RC = -5629,
    // The Mono debugger does not support watchpoints on local variables
    DEBUG_MONO_LOCAL_WATCHPOINT_NOT_SUPPORTED_RC = -5630,
    // Can not modify the value of property
    DEBUG_MONO_ERROR_MODIFYING_PROPERTY_RC = -5631,
    // Can not modify a character in a string
    DEBUG_MONO_ERROR_MODIFYING_STRING_RC = -5632,
    // Packet header contains invalid packet size
    DEBUG_DBGP_INVALID_PACKET_SIZE_RC = -5650,
    // No more data
    DEBUG_DBGP_NO_MORE_DATA_RC = -5651,
    // Already connected
    DEBUG_DBGP_ALREADY_CONNECTED_RC = -5652,
    // Something unexpected
    DEBUG_DBGP_UNEXPECTED_RC = -5653,
    // Not connected
    DEBUG_DBGP_NOT_CONNECTED_RC = -5654,
    // Version not supported
    DEBUG_DBGP_VERSION_NOT_SUPPORTED_RC = -5655,
    // Command not supported
    DEBUG_DBGP_COMMAND_NOT_SUPPORTED_RC = -5656,
    // Received empty reply packet
    DEBUG_GDB_EMPTY_REPLY_RC = -5700,
    // Timed out waiting for response from GDB
    DEBUG_GDB_TIMEOUT_RC = -5701,
    // GDB has terminated prematurely
    DEBUG_GDB_TERMINATED_RC = -5702,
    // The application has exited
    DEBUG_GDB_APP_EXITED_RC = -5703,
    // Received an invalid reply
    DEBUG_GDB_INVALID_REPLY_RC = -5704,
    // Received an error message
    DEBUG_GDB_ERROR_REPLY_RC = -5705,
    // Operations on individual threads are not supported
    DEBUG_GDB_THREAD_OPERATION_UNSUPPORTED_RC = -5706,
    // GDB returned an error opening the executable
    DEBUG_GDB_ERROR_OPENING_FILE_RC = -5707,
    // GDB returned an error setting the program arguments
    DEBUG_GDB_ERROR_SETTING_ARGS_RC = -5708,
    // GDB returned an error attaching to the process ID
    DEBUG_GDB_ERROR_ATTACHING_RC = -5709,
    // GDB returned an error listing threads
    DEBUG_GDB_ERROR_LISTING_THREADS_RC = -5710,
    // GDB returned an error selecting a thread
    DEBUG_GDB_ERROR_SELECTING_THREAD_RC = -5711,
    // GDB returned an error selecting a stack frame
    DEBUG_GDB_ERROR_SELECTING_FRAME_RC = -5712,
    // GDB returned an error listing stack frames
    DEBUG_GDB_ERROR_LISTING_STACK_RC = -5713,
    // GDB returned an error listing local variables
    DEBUG_GDB_ERROR_LISTING_LOCALS_RC = -5714,
    // GDB returned an error listing arguments
    DEBUG_GDB_ERROR_LISTING_ARGUMENTS_RC = -5715,
    // GDB could not evaluate expression
    DEBUG_GDB_ERROR_EVALUATING_EXPRESSION_RC = -5716,
    // GDB returned an error modifying this variable
    DEBUG_GDB_ERROR_MODIFYING_VARIABLE_RC = -5717,
    // GDB could not continue application
    DEBUG_GDB_ERROR_CONTINUING_RC = -5718,
    // GDB could not start application
    DEBUG_GDB_ERROR_RUNNING_RC = -5719,
    // GDB could not step application
    DEBUG_GDB_ERROR_STEPPING_RC = -5720,
    // GDB returned an error when interrupting application
    DEBUG_GDB_ERROR_INTERRUPT_RC = -5721,
    // GDB returned an error setting breakpoint
    DEBUG_GDB_ERROR_SETTING_BREAKPOINT_RC = -5722,
    // GDB returned an error deleting breakpoint
    DEBUG_GDB_ERROR_DELETING_BREAKPOINT_RC = -5723,
    // GDB returned an error suspending the application
    DEBUG_GDB_ERROR_SUSPENDING_RC = -5724,
    // Did not receive correct handshake from vsdebugio
    DEBUG_GDB_INVALID_HANDSHAKE_RC = -5725,
    // Invalid packet header received by vsdebugio
    DEBUG_GDB_INVALID_PACKET_RC = -5726,
    // Error detaching debugger from target process
    DEBUG_GDB_ERROR_DETACHING_RC = -5727,
    // Error listing registers
    DEBUG_GDB_ERROR_LISTING_REGISTERS_RC = -5728,
    // Error listing memory contents
    DEBUG_GDB_ERROR_LISTING_MEMORY_RC = -5729,
    // All pseudo-terminals (ptys) are in use
    DEBUG_GDB_ALL_PTYS_IN_USE_RC = -5730,
    // Cannot open slave pseudo-terminal (pty)
    DEBUG_GDB_CANNOT_OPEN_SLAVE_PTY_RC = -5731,
    // GNU debugger (gdb) not found
    DEBUG_GDB_MISSING_GDB_RC = -5732,
    // GDB returned an error attaching to the remote process
    DEBUG_GDB_ERROR_ATTACHING_REMOTE_RC = -5733,
    // GDB returned an error attaching to the core file
    DEBUG_GDB_ERROR_ATTACHING_CORE_RC = -5734,
    // Error starting gdb proxy application
    DEBUG_GDB_ERROR_STARTING_PROXY_RC = -5735,
    // The gdb proxy application is not running
    DEBUG_GDB_PROXY_NOT_RUNNING_RC = -5736,
    // Error sending message to gdb proxy application
    DEBUG_GDB_PROXY_ERROR_SENDING_RC = -5737,
    // Could not find the gdb proxy application window
    DEBUG_GDB_PROXY_WINDOW_NOT_FOUND_RC = -5738,
    // Could not find the gdb proxy application
    DEBUG_GDB_PROXY_NOT_FOUND_RC = -5739,
    // GDB returned an error listing disassembly
    DEBUG_GDB_ERROR_LISTING_DISASSEMBLY_RC = -5740,
    // String value truncated by GDB
    DEBUG_GDB_TRUNCATED_VALUE_RC = -5741,
    // Received an exit message
    DEBUG_GDB_EXIT_REPLY_RC = -5742,
    // GDB returned an error moving instruction pointer
    DEBUG_GDB_ERROR_SETTING_INSTRUCTION_POINTER_RC = -5743,
    // No process running
    DEBUG_DOTNET_NO_PROCESS_RC = -5800,
    // An error occurred while listing threads
    DEBUG_DOTNET_ERROR_LISTING_THREADS_RC = -5801,
    // An error occurred while stack frames
    DEBUG_DOTNET_ERROR_LISTING_STACK_RC = -5802,
    // No current managed MSIL frame
    DEBUG_DOTNET_NO_CURRENT_MANAGED_FRAME_RC = -5803,
    // Cannot get variable names
    DEBUG_DOTNET_ERROR_GETTING_VARIABLES_RC = -5804,
    // Error getting code for frame
    DEBUG_DOTNET_ERROR_GETTING_CODE_RC = -5805,
    // Error getting function for frame
    DEBUG_DOTNET_ERROR_GETTING_FUNCITON_RC = -5806,
    // Error getting line number
    DEBUG_DOTNET_ERROR_GETTING_LINE_RC = -5807,
    // Could not start app for debugging
    DEBUG_DOTNET_COULD_NOT_START_DEBUGGEE_RC = -5808,
    // The pdb file is out of date.  This project needs to be rebuilt.
    DEBUG_DOTNET_PDB_FILE_OUT_OF_DATE_RC = -5809,
    // Variable specified is not an array
    DEBUG_DOTNET_NOT_AN_ARRAY_RC = -5810,
    // The function has no managed body
    DEBUG_DOTNET_CORDBG_E_FUNCTION_NOT_IL_RC = -5811,
    // Unrecoverable internal error
    DEBUG_DOTNET_CORDBG_E_UNRECOVERABLE_ERROR_RC = -5812,
    // The debuggee has terminated
    DEBUG_DOTNET_CORDBG_E_PROCESS_TERMINATED_RC = -5813,
    // Unable to process while debuggee is running
    DEBUG_DOTNET_CORDBG_E_PROCESS_NOT_SYNCHRONIZED_RC = -5814,
    // A class has not been loaded yet by the debuggee
    DEBUG_DOTNET_CORDBG_E_CLASS_NOT_LOADED_RC = -5815,
    // The variable is not available
    DEBUG_DOTNET_CORDBG_E_IL_VAR_NOT_AVAILABLE_RC = -5816,
    // The reference is invalid
    DEBUG_DOTNET_CORDBG_E_BAD_REFERENCE_VALUE_RC = -5817,
    // The field is not available.
    DEBUG_DOTNET_CORDBG_E_FIELD_NOT_AVAILABLE_RC = -5818,
    // The field is not available because it is a constant optimized away by the runtime.
    DEBUG_DOTNET_CORDBG_E_VARIABLE_IS_ACTUALLY_LITERAL_RC = -5819,
    // The frame type is incorrect
    DEBUG_DOTNET_CORDBG_E_NON_NATIVE_FRAME_RC = -5820,
    // The exception cannot be continued from
    DEBUG_DOTNET_CORDBG_E_NONCONTINUABLE_EXCEPTION_RC = -5821,
    // The code is not available at this time
    DEBUG_DOTNET_CORDBG_E_CODE_NOT_AVAILABLE_RC = -5822,
    // The operation cannot be started at the current IP
    DEBUG_DOTNET_CORDBG_S_BAD_START_SEQUENCE_POINT_RC = -5823,
    // The destination IP is not valid
    DEBUG_DOTNET_CORDBG_S_BAD_END_SEQUENCE_POINT_RC = -5824,
    // Insufficient information to perform Set IP
    DEBUG_DOTNET_CORDBG_S_INSUFFICIENT_INFO_FOR_SET_IP_RC = -5825,
    // Cannot Set IP into a finally clause
    DEBUG_DOTNET_CORDBG_E_CANT_SET_IP_INTO_FINALLY_RC = -5826,
    // Cannot Set IP out of a finally clause
    DEBUG_DOTNET_CORDBG_E_CANT_SET_IP_OUT_OF_FINALLY_RC = -5827,
    // Cannot Set IP into a catch clause
    DEBUG_DOTNET_CORDBG_E_CANT_SET_IP_INTO_CATCH_RC = -5828,
    // Unable to Set IP
    DEBUG_DOTNET_CORDBG_E_SET_IP_IMPOSSIBLE_RC = -5829,
    // Can't Set IP on a non-leaf frame
    DEBUG_DOTNET_CORDBG_E_SET_IP_NOT_ALLOWED_ON_NONLEAF_FRAME_RC = -5830,
    // Cannot perform a function evaluation at the current IP
    DEBUG_DOTNET_CORDBG_E_FUNC_EVAL_BAD_START_POINT_RC = -5831,
    // The object value is no longer valid
    DEBUG_DOTNET_CORDBG_E_INVALID_OBJECT_RC = -5832,
    // The function evaluation is still being processed
    DEBUG_DOTNET_CORDBG_E_FUNC_EVAL_NOT_COMPLETE_RC = -5833,
    // The function evaluation has no result
    DEBUG_DOTNET_CORDBG_S_FUNC_EVAL_HAS_NO_RESULT_RC = -5834,
    // Can't dereference a void pointer
    DEBUG_DOTNET_CORDBG_S_VALUE_POINTS_TO_VOID_RC = -5835,
    // The API is not usable in-process
    DEBUG_DOTNET_CORDBG_E_INPROC_NOT_IMPL_RC = -5836,
    // The function evaluation was aborted
    DEBUG_DOTNET_CORDBG_S_FUNC_EVAL_ABORTED_RC = -5837,
    // The static variable is not available (not yet initialized)
    DEBUG_DOTNET_CORDBG_E_STATIC_VAR_NOT_AVAILABLE_RC = -5838,
    // The value class object cannot be copied
    DEBUG_DOTNET_CORDBG_E_OBJECT_IS_NOT_COPYABLE_VALUE_CLASS_RC = -5839,
    // Cannot Set IP into or out of a filter
    DEBUG_DOTNET_CORDBG_E_CANT_SETIP_INTO_OR_OUT_OF_FILTER_RC = -5840,
    // Cannot change JIT setting for pre-jitted module
    DEBUG_DOTNET_CORDBG_E_CANT_CHANGE_JIT_SETTING_FOR_ZAP_MODULE_RC = -5841,
    // The thread's state is invalid
    DEBUG_DOTNET_CORDBG_E_BAD_THREAD_STATE_RC = -5842,
    // Debugging is not possible due to a runtime configuration issue
    DEBUG_DOTNET_CORDBG_E_DEBUGGING_NOT_POSSIBLE_RC = -5843,
    // Debugging is not possible because there is a kernel debugger enabled on your system
    DEBUG_DOTNET_CORDBG_E_KERNEL_DEBUGGER_ENABLED_RC = -5844,
    // Debugging is not possible because there is a kernel debugger present on your system
    DEBUG_DOTNET_CORDBG_E_KERNEL_DEBUGGER_PRESENT_RC = -5845,
    // The process cannot be debugged because the debugger's internal debugging protocol is incompatible with the protocol supported by the process.
    DEBUG_DOTNET_CORDBG_E_INCOMPATIBLE_PROTOCOL_RC = -5846,
    // First chance exception generated: 
    DEBUG_DOTNET_FIRST_CHANCE_EXCEPTION_RC = -5847,
    // Unexpected error occurred: 
    DEBUG_DOTNET_UNEXPECTED_ERROR_RC = -5848,
    // Unhandled exception generated: 
    DEBUG_DOTNET_UNHANDLED_EXCEPTION_RC = -5849,
    // Process not running.
    DEBUG_DOTNET_PROCESS_NOT_RUNNING_RC = -5850,
    // Thread no longer exists.
    DEBUG_DOTNET_THREAD_NO_LONGER_EXISTS_RC = -5851,
    // Could not create stepper.
    DEBUG_DOTNET_CREATE_STEPPER_FAILED_RC = -5852,
    // A debugger is already attached to this process.
    DEBUG_DOTNET_DEBUGGER_ALREADY_ATTACHED_RC = -5853,
    // Restart is not allowed for this debugger target
    DEBUG_CAN_NOT_RESTART_RC = -5854,
    // Error getting variables for stack frame.
    DEBUG_DAP_ERROR_GETTING_VARIABLES = -5855,
    // , 
    DEBUG_CAPTION_SEPARATOR_RC = -5900,
    // Verified
    DEBUG_CAPTION_VERIFIED_RC = -5901,
    // Prepared
    DEBUG_CAPTION_PREPARED_RC = -5902,
    // Initialized
    DEBUG_CAPTION_INITIALIZED_RC = -5903,
    // Error
    DEBUG_CAPTION_ERROR_RC = -5904,
    // Unknown
    DEBUG_CAPTION_UNKNOWN_RC = -5905,
    // Monitor
    DEBUG_CAPTION_MONITOR_RC = -5906,
    // Running
    DEBUG_CAPTION_RUNNING_RC = -5907,
    // Sleeping
    DEBUG_CAPTION_SLEEPING_RC = -5908,
    // Waiting
    DEBUG_CAPTION_WAITING_RC = -5909,
    // Zombie
    DEBUG_CAPTION_ZOMBIE_RC = -5910,
    // Suspended
    DEBUG_CAPTION_SUSPENDED_RC = -5911,
    // Alive
    DEBUG_CAPTION_ALIVE_RC = -5912,
    // [Default]
    DEBUG_CAPTION_DEFAULT_RC = -5913,
    // item
    DEBUG_CAPTION_ITEM_RC = -5914,
    // items
    DEBUG_CAPTION_ITEMS_RC = -5915,
    // null
    DEBUG_CAPTION_NULL_RC = -5916,
    // true
    DEBUG_CAPTION_TRUE_RC = -5917,
    // false
    DEBUG_CAPTION_FALSE_RC = -5918,
    // void
    DEBUG_CAPTION_VOID_RC = -5919,
    // class
    DEBUG_CAPTION_CLASS_RC = -5920,
    // Thrown
    DEBUG_CAPTION_THROWN_RC = -5921,
    // Caught
    DEBUG_CAPTION_CAUGHT_RC = -5922,
    // Uncaught
    DEBUG_CAPTION_UNCAUGHT_RC = -5923,
    // Ignore
    DEBUG_CAPTION_IGNORE_RC = -5924,
    // Current execution line
    DEBUG_CAPTION_CURR_TOP_OF_STACK_RC = -5925,
    // A line on the execution call stack
    DEBUG_CAPTION_CURR_FRAME_OF_STACK_RC = -5926,
    // Last current execution line
    DEBUG_CAPTION_LAST_TOP_OF_STACK_RC = -5927,
    // A line on the last execution call stack
    DEBUG_CAPTION_LAST_FRAME_OF_STACK_RC = -5928,
    // Enabled breakpoint
    DEBUG_CAPTION_BREAKPOINT_ENABLED_RC = -5929,
    // Disabled breakpoint
    DEBUG_CAPTION_BREAKPOINT_DISABLED_RC = -5930,
    // Frozen
    DEBUG_CAPTION_FROZEN_RC = -5931,
    // undefined
    DEBUG_CAPTION_UNDEFINED_VALUE_RC = -5932,
    // Enabled watchpoint
    DEBUG_CAPTION_WATCHPOINT_ENABLED_RC = -5933,
    // Disabled watchpoint
    DEBUG_CAPTION_WATCHPOINT_DISABLED_RC = -5934,
    // package
    DEBUG_CAPTION_PACKAGE_RC = -5935,
    // function
    DEBUG_CAPTION_FUNCTION_RC = -5936,
};
#endif

#ifndef VSMSGDEFS_JDWP_H
#define VSMSGDEFS_JDWP_H
enum VSMSGDEFS_JDWP {
    // JDWP error: No error has occurred
    JDWP_ERROR_NONE_RC = -6000,
    // JDWP error: Passed thread is not a valid thread or has exited
    JDWP_ERROR_INVALID_THREAD_RC = -6010,
    // JDWP error: Invalid thread group
    JDWP_ERROR_INVALID_THREAD_GROUP_RC = -6011,
    // JDWP error: Invalid priority setting
    JDWP_ERROR_INVALID_PRIORITY_RC = -6012,
    // JDWP error: Thread not suspended
    JDWP_ERROR_THREAD_NOT_SUSPENDED_RC = -6013,
    // JDWP error: Thread already suspended
    JDWP_ERROR_THREAD_SUSPENDED_RC = -6014,
    // JDWP error: Passed object is invalid or has been unloaded and garbage collected
    JDWP_ERROR_INVALID_OBJECT_RC = -6020,
    // JDWP error: Invalid class ID
    JDWP_ERROR_INVALID_CLASS_RC = -6021,
    // JDWP error: Class has been loaded but not yet prepared
    JDWP_ERROR_CLASS_NOT_PREPARED_RC = -6022,
    // JDWP error: Invalid method ID
    JDWP_ERROR_INVALID_METHODID_RC = -6023,
    // JDWP error: Invalid location
    JDWP_ERROR_INVALID_LOCATION_RC = -6024,
    // JDWP error: Invalid field ID
    JDWP_ERROR_INVALID_FIELDID_RC = -6025,
    // JDWP error: Invalid frame ID
    JDWP_ERROR_INVALID_FRAMEID_RC = -6030,
    // JDWP error: There are no more Java or JNI frames on the call stack
    JDWP_ERROR_NO_MORE_FRAMES_RC = -6031,
    // JDWP error: Information about the frame is unavailable
    JDWP_ERROR_OPAQUE_FRAME_RC = -6032,
    // JDWP error: Operation can only be performed on the current frame
    JDWP_ERROR_NOT_CURRENT_FRAME_RC = -6033,
    // JDWP error: The variable is not an appropriate type for the function used
    JDWP_ERROR_TYPE_MISMATCH_RC = -6034,
    // JDWP error: Invalid slot
    JDWP_ERROR_INVALID_SLOT_RC = -6035,
    // JDWP error: Item already set
    JDWP_ERROR_DUPLICATE_RC = -6040,
    // JDWP error: Requested item not found
    JDWP_ERROR_NOT_FOUND_RC = -6041,
    // JDWP error: Invalid monitor
    JDWP_ERROR_INVALID_MONITOR_RC = -6050,
    // JDWP error: This thread doesn't own the monitor
    JDWP_ERROR_NOT_MONITOR_OWNER_RC = -6051,
    // JDWP error: The call has been interrupted before completion
    JDWP_ERROR_INTERRUPT_RC = -6052,
    // JDWP error: The virtual machine attempted to read a malformed class file
    JDWP_ERROR_INVALID_CLASS_FORMAT_RC = -6060,
    // JDWP error: A circularity has been detected while initializing a class
    JDWP_ERROR_CIRCULAR_CLASS_DEFINITION_RC = -6061,
    // JDWP error: Class failed verification
    JDWP_ERROR_FAILS_VERIFICATION_RC = -6062,
    // JDWP error: Add method not implemented
    JDWP_ERROR_ADD_METHOD_NOT_IMPLEMENTED_RC = -6063,
    // JDWP error: Schema change not implemented
    JDWP_ERROR_SCHEMA_CHANGE_NOT_IMPLEMENTED_RC = -6064,
    // JDWP error: The state of the thread has been modified and is now inconsistent
    JDWP_ERROR_INVALID_TYPESTATE_RC = -6065,
    // JDWP error: A direct superclass is different for the new class version
    JDWP_ERROR_HIERARCHY_CHANGE_NOT_IMPLEMENTED_RC = -6066,
    // JDWP error: The new class version does not implement a method declared in the old class version
    JDWP_ERROR_DELETE_METHOD_NOT_IMPLEMENTED_RC = -6067,
    // JDWP error: A class file has a version number not supported by this VM
    JDWP_ERROR_UNSUPPORTED_VERSION_RC = -6068,
    // JDWP error: The class name defined in the new class file does not match the original class name
    JDWP_ERROR_NAMES_DONT_MATCH_RC = -6069,
    // JDWP error: The new class version has different modifiers than the original class
    JDWP_ERROR_CLASS_MODIFIERS_CHANGE_NOT_IMPLEMENTED_RC = -6070,
    // JDWP error: A method in the new class version has different modifiers than the original method
    JDWP_ERROR_METHOD_MODIFIERS_CHANGE_NOT_IMPLEMENTED_RC = -6071,
    // JDWP error: Feature not implemented in this virtual machine
    JDWP_ERROR_NOT_IMPLEMENTED_RC = -6099,
    // JDWP error: Null pointer
    JDWP_ERROR_NULL_POINTER_RC = -6100,
    // JDWP error: Requested information is not available
    JDWP_ERROR_ABSENT_INFORMATION_RC = -6101,
    // JDWP error: The specified event type is not recognized
    JDWP_ERROR_INVALID_EVENT_TYPE_RC = -6102,
    // JDWP error: Illegal argument
    JDWP_ERROR_ILLEGAL_ARGUMENT_RC = -6103,
    // JDWP error: Out of memory
    JDWP_ERROR_OUT_OF_MEMORY_RC = -6110,
    // JDWP error: Access denied; Debugging may not be enabled on this virtual machine
    JDWP_ERROR_ACCESS_DENIED_RC = -6111,
    // JDWP error: The virtual machine is not running
    JDWP_ERROR_VM_DEAD_RC = -6112,
    // JDWP error: An unexpected internal error has occurred in the virtual machine
    JDWP_ERROR_INTERNAL_RC = -6113,
    // JDWP error: The thread being used to call this function is not attached to the virtual machine
    JDWP_ERROR_UNATTACHED_THREAD_RC = -6115,
    // JDWP error: Invalid object type ID or class tag
    JDWP_ERROR_INVALID_TAG_RC = -6500,
    // JDWP error: Previous method or constructor invocation not complete
    JDWP_ERROR_ALREADY_INVOKING_RC = -6502,
    // JDWP error: Invalid array index
    JDWP_ERROR_INVALID_INDEX_RC = -6503,
    // JDWP error: Invalid array length
    JDWP_ERROR_INVALID_LENGTH_RC = -6504,
    // JDWP error: Invalid string
    JDWP_ERROR_INVALID_STRING_RC = -6506,
    // JDWP error: Invalid class loader
    JDWP_ERROR_INVALID_CLASS_LOADER_RC = -6507,
    // JDWP error: Invalid array object
    JDWP_ERROR_INVALID_ARRAY_RC = -6508,
    // JDWP error: Error loading transport layer
    JDWP_ERROR_TRANSPORT_LOAD_RC = -6509,
    // JDWP error: Error initializing transport layer
    JDWP_ERROR_TRANSPORT_INIT_RC = -6510,
    // JDWP error: Operation not allowed for native methods
    JDWP_ERROR_NATIVE_METHOD_RC = -6511,
    // JDWP error: Invalid item count
    JDWP_ERROR_INVALID_COUNT_RC = -6512,
    // JDWP error: The specified command set is not recognized
    JDWP_ERROR_INVALID_COMMAND_SET_RC = -6513,
    // JDWP error: The specified command is not recognized
    JDWP_ERROR_INVALID_COMMAND_RC = -6514,
};
#endif

#ifndef VSMSGDEFS_CVS_H
#define VSMSGDEFS_CVS_H
enum VSMSGDEFS_CVS {
    // CVS error: You are not logged on
    CVS_ERROR_NOT_LOGGED_IN = -6600,
    // CVS executable not found
    CVS_ERROR_EXE_NOT_FOUND = -6601,
    // CVS checkout failed
    CVS_ERROR_CHECKOUT_FAILED_RC = -6602,
};
#endif

#ifndef VSMSGDEFS_SUBVERSION_H
#define VSMSGDEFS_SUBVERSION_H
enum VSMSGDEFS_SUBVERSION {
   // {0} {1} returned {2}
   SVN_COMMAND_RETURNED_ERROR_RC = -6650,
   // This command does not support directories
   SVN_DIRECTORIES_NOT_SUPPORTED_RC = -6651,
    // This file was not checked out from {0}
   SVN_FILE_NOT_CONTROLLED_RC = -6652,
   // Subversion
   SVN_APP_NAME_RC = -6653,
   // Could not get log information for {0}
   SVN_COULD_NOT_GET_LOG_INFO_RC = -6654,
   // Subversion checkout failed
   SVN_ERROR_CHECKOUT_FAILED_RC = -6655,
   // Can't get Subversion password (perform "svn status" from console)
   SVN_ERROR_CANT_GET_PASSWORD = -6656,
   // Subversion output exceeds configured maximum output size
   SVN_OUTPUT_TOO_LARGE = -6657,
   // Subversion returned an error for the path(s): {0}
   SVN_COMMAND_RETURNED_ERROR_FOR_PATH_RC = -6658,
};
#endif

#ifndef VSMSGDEFS_SLICKLEX_H
#define VSMSGDEFS_SLICKLEX_H
enum VSMSGDEFS_SLICKLEX {
    // Usage: slicklex [Options] lexer.slex ...
    // 
    //    lexer.slex      Name of XML lexer specification file
    //    -o | --output   Specify output directory
    //    -f | --force    Force output file to be regenerated
    //    -v | --verbose  Verbose output
    //    -h | --help     Show this message
    // 
    // Example
    //     slicklex CPPLexer.slex
    //         Regenerates CPPLexerGen.cpp
    // 
    VSRC_SLICKLEX_USAGE = -6700,
    // slicklex - Invalid arguments: {0}
    VSRC_SLICKLEX_INVALID_ARGUMENT = -6701,
    // slicklex - could not find file "{0}"
    VSRC_SLICKLEX_FILE_NOT_FOUND = -6702,
    // slicklex - could not read file "{0}"
    VSRC_SLICKLEX_FILE_NOT_READ = -6703,
    // slicklex - could not write file "{0}"
    VSRC_SLICKLEX_FILE_NOT_WRITTEN = -6704,
    // slicklex - filename={0}, number of tokens={1}, case sensitive={2}, target={3}
    VSRC_SLICKLEX_TOKEN_REPORT = -6705,
    // slicklex - no changes to output file: {0}
    VSRC_SLICKLEX_OUTPUT_UNCHANGED = -6706,
    // slicklex - regenerated output file: {0}
    VSRC_SLICKLEX_OUTPUT_REGENERATED = -6707,
    // slicklex - could not find output directory "{0}"
    VSRC_SLICKLEX_DIR_NOT_FOUND = -6708,
    // slicklex - parser generator specification can only contain one lexer specification and one parser specification
    VSRC_SLICKLEX_ONLY_ONE_ALLOWED = -6709,
    // slicklex - expecting parser generator specification
    VSRC_SLICKLEX_EXPECTING_PARSER = -6710,
    // {0} ({1}): slicklex - duplicate token id "{2}"
    VSRC_SLICKLEX_DUPLICATE_TOKEN_ID = -6711,
    // {0} ({1}): slicklex - duplicate token text "{2}"
    VSRC_SLICKLEX_DUPLICATE_TOKEN = -6712,
    // {0} ({1}): slicklex - duplicate parser rule name "{2}"
    VSRC_SLICKLEX_DUPLICATE_RULE = -6713,
    // {0} ({1}): slicklex - in rule {2} - duplicate argument name "{3}"
    VSRC_SLICKLEX_DUPLICATE_ARGUMENT_NAME = -6714,
    // {0} ({1}): slicklex - in rule {2} - undefined rule "{3}"
    VSRC_SLICKLEX_UNDEFINED_RULE = -6715,
    // {0} ({1}): slicklex - in rule {2} - undefined token "{3}"
    VSRC_SLICKLEX_UNDEFINED_TOKEN = -6716,
    // {0} ({1}): slicklex - invalid rule, "id" attribute is required
    VSRC_SLICKLEX_MISSING_RULE_ID = -6717,
    // {0} ({1}): slicklex - invalid rule, invalid "id" name "{2}"
    VSRC_SLICKLEX_INVALID_RULE_NAME = -6718,
    // {0} ({1}): slicklex - in rule {2} - expecting tokens (not <{3}>) in <{4}> clause
    VSRC_SLICKLEX_EXPECTING_TOKEN = -6719,
    // {0} ({1}): slicklex - in rule {2} - expecting rules (not <{3}>) in <{4}> clause
    VSRC_SLICKLEX_EXPECTING_RULE = -6720,
    // {0} ({1}): slicklex - in rule {2} - expecting case (not <{3}>) in <{4}> clause
    VSRC_SLICKLEX_EXPECTING_CASE = -6721,
    // {0} ({1}): slicklex - in rule {2} - invalid clause tag <{3}>
    VSRC_SLICKLEX_INVALID_TAG = -6722,
    // slicklex - handling keywords using hashing method
    VSRC_SLICKLEX_KEYWORDS_ARE_HASHED = -6723,
    // slicklex - number of keywords = {0}, number of hash slots = {1}
    VSRC_SLICKLEX_KEYWORD_HASH_STATS = -6724,
    // slicklex - handling keywords by separating them by length
    VSRC_SLICKLEX_KEYWORDS_BY_LENGTH = -6725,
    // slicklex - number of keywords = {0}, max keyword length = {1}
    VSRC_SLICKLEX_KEYWORD_LENGTH_STATS = -6726,
    // {0} ({1}): slicklex - in rule {2} - keyword "{3}" used as identifier
    VSRC_SLICKLEX_KEYWORD_USED_AS_IDENTIFIER = -6727,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has multiple <Default> clauses
    VSRC_SLICKLEX_OR_HAS_MULTIPLE_DEFAULTS = -6728,
    // {0} ({1}): slicklex - in rule {2} - duplicate variable name "{3}"
    VSRC_SLICKLEX_DUPLICATE_VARIABLE_NAME = -6729,
    // {0} ({1}): slicklex - in rule {2} - duplicate id name "{3}"
    VSRC_SLICKLEX_DUPLICATE_ID_NAME = -6730,
    // {0} ({1}): slicklex - in rule {2} - unexpected rule name in <{3}> clause"
    VSRC_SLICKLEX_UNEXPECTED_RULE_NAME = -6731,
    // {0} ({1}): slicklex - in rule {2} - no such id name "{3}"
    VSRC_SLICKLEX_ID_NAME_NOT_FOUND = -6732,
    // {0} ({1}): slicklex - in rule {2} - missing required attribute "{3}" for "{4}"
    VSRC_SLICKLEX_MISSING_ATTRIBUTE = -6733,
    // {0} ({1}): slicklex - in rule {2} - too many arguments for rule "{3}"
    VSRC_SLICKLEX_TOO_MANY_ARGUMENTS = -6734,
    // {0} ({1}): slicklex - in rule {2} - not enough arguments for rule "{3}"
    VSRC_SLICKLEX_TOO_FEW_ARGUMENTS = -6735,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has no cases
    VSRC_SLICKLEX_OR_HAS_NO_CASES = -6736,
    // {0} ({1}): slicklex - in rule {2} - repeat clause could have infinite loop
    VSRC_SLICKLEX_INFINITE_LOOP_IN_REPEAT = -6737,
    // {0} ({1}): slicklex - unexpected XML tag <{2}>
    VSRC_SLICKLEX_UNEXPECTED_TAG = -6738,
    // {0} ({1}): slicklex warning - unused grammar rule: {2}
    VSRC_SLICKLEX_UNUSED_RULE = -6740,
    // {0} ({1}): slicklex - in rule {2} - "Name" attribute is required for <{3}>
    VSRC_SLICKLEX_MISSING_RULE_NAME = -6741,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has only one case
    VSRC_SLICKLEX_OR_HAS_ONE_CASE = -6742,
    // {0} ({1}): slicklex - in rule {2} - left recursion detected calling rule "{3}"
    VSRC_SLICKLEX_INFINITE_RECURSION = -6743,
    // slicklex - rule={0}: num_clauses={1}, min tokens={2}, max tokens={3}
    VSRC_SLICKLEX_RULE_REPORT = -6744,
    // slicklex - {0}{1}, min tokens={2}, max tokens={3}
    VSRC_SLICKLEX_CLAUSE_REPORT = -6745,
    // slicklex - filename={0}, number of rules={1}, case sensitive={2}, target={3}
    VSRC_SLICKLEX_PARSER_REPORT = -6746,
    // {0} ({1}): slicklex - in rule {2} - expecting rules or tokens (not <{3}>) in <{4}> clause
    VSRC_SLICKLEX_EXPECTING_RULE_OR_TOKEN = -6747,
    // {0} ({1}): slicklex warning - unused token: "{2}"
    VSRC_SLICKLEX_UNUSED_TOKEN = -6748,
    // {0} ({1}): slicklex - see rule definition {2}
    VSRC_SLICKLEX_SEE_RULE = -6749,
    // {0} ({1}): slicklex - in rule {2} - argument "{3}" has no default
    VSRC_SLICKLEX_MISSING_DEFAULT = -6750,
    // {0} ({1}): slicklex - in rule {2} - expecting operator or operand (not <{3}>) in <{4}> clause
    VSRC_SLICKLEX_EXPECTING_OPERATORS = -6751,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has no binary operators
    VSRC_SLICKLEX_EXPRESSION_HAS_NO_OPERATORS = -6752,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has no operand expression
    VSRC_SLICKLEX_EXPRESSION_HAS_NO_OPERAND = -6753,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has multiple operand expressions
    VSRC_SLICKLEX_EXPRESSION_HAS_MULTIPLE_OPERANDS = -6754,
    // {0} ({1}): slicklex - in rule {2} - <{3}> has too many precedence levels
    VSRC_SLICKLEX_EXPRESSION_HAS_EXCESSIVE_OPERATORS = -6756,
    // {0} ({1}): slicklex - in rule {2} - <{3}> only allowed in <{4}> tag, not <{5}>
    VSRC_SLICKLEX_EXPRESSION_INVALID_TAG_CONTEXT = -6757,
    // {0} ({1}): slicklex - lexer file not found: "{2}"
    VSRC_SLICKLEX_LEXER_FILE_NOT_FOUND = -6758,
    // {0} ({1}): slicklex - IdToken "{2}" is Token in "{3}"
    VSRC_SLICKLEX_LEXER_IDTOKEN_IS_TOKEN = -6759,
    // {0} ({1}): slicklex - Token "{2}" is IdToken in "{3}"
    VSRC_SLICKLEX_LEXER_TOKEN_IS_IDTOKEN = -6760,
    // {0} ({1}): slicklex - see token definition for "{2}"
    VSRC_SLICKLEX_LEXER_SEE_TOKEN_DEFINITION = -6761,
    // {0} ({1}): slicklex - in rule {2} - unterminated argument list for rule "{3}"
    VSRC_SLICKLEX_UNTERMINATED_ARGUMENT_LIST = -6762,
    // {0} ({1}): slicklex - in rule {2} - missing type for argument "{3}"
    VSRC_SLICKLEX_MISSING_ARGUMENT_TYPE = -6763,
    // {0} ({1}): slicklex - in rule {2} - pass by reference can not have default for argument "{3}"
    VSRC_SLICKLEX_REF_ARGUMENT_HAS_DEFAULT = -6764,
    // {0} ({1}): slicklex - in rule {2} - misplaced <{3}> tag
    VSRC_SLICKLEX_MISPLACED_ARGUMENT_TAG = -6765,
    // {0} ({1}): slicklex - in rule {2} - invalid type for argument "{3}"
    VSRC_SLICKLEX_INVALID_ARGUMENT_TYPE = -6766,
    // {0} ({1}): slicklex - in rule {2} - function body tracking disabled"
    VSRC_SLICKLEX_NO_IN_FUNCTION_TRACKING = -6767,
    // {0} ({1}): slicklex - in rule {2} - class name tracking disabled"
    VSRC_SLICKLEX_NO_CLASS_NAME_TRACKING = -6768,
    // {0} ({1}): slicklex - token requires Text or StartRegex
    VSRC_SLICKLEX_NO_TOKEN_TEXT = -6769,
    // {0} ({1}): slicklex - token requires StartRegex with Regex
    VSRC_SLICKLEX_NO_TOKEN_START_REGEX = -6770,
};
#endif

#ifndef VSMSGDEFS_UPDATE_H
#define VSMSGDEFS_UPDATE_H
enum VSMSGDEFS_UPDATE {
    // Could not write to file {0}
    // 
    // Possible Causes:
    // 
    // *Do not have write permissions for file
    // 
    // *Out of disk space
    UPDATE_CANNOT_WRITE_FILE_RC = -6800,
    // Error copying files
    UPDATE_GENERAL_COPY_ERROR_RC = -6801,
    // Could not backup file {0}
    // 
    // Continue?
    UPDATE_BACKUP_ERROR_RC = -6802,
    // Could not create path {0}
    UPDATE_COULD_NOT_CREATE_PATH_ERROR_RC = -6803,
    // Updating Files - {0}
    UPDATE_UPDATING_FILES_RC = -6804,
    // Compiling Macro Files - {0}
    UPDATE_COMPILING_FILES_RC = -6805,
    // File {1} does not exist in the specified path
    UPDATE_FILE_DOES_NOT_EXIST_RC = -6806,
    // Could not copy serial information to new {0}.
    // Possible Causes:
    // 
    // 	* The executable path "{1}" is incorrect.
    // 
    // 	* Someone is running {2}.
    // 
    // 	* {3}{4} is a demo executable.
    // 
    // 	* {5}{6} is an old version and cannot be updated with this program
    UPDATE_COULD_NOT_SERIALIZE_RC = -6807,
    // Could not decompress {0}
    UPDATE_COULD_NOT_DECOMPRESS_VSAPI_RC = -6808,
    // Could not find uninstall list file.  SlickEdit's uninstall may fail to remove some new files in this patch.
    // 
    // Continue?
    UPDATE_COULD_NOT_FIND_UNINST_LIST_RC = -6809,
    // {0} is a trial install, and cannot be updated
    // 
    // To purchase please contact sales at SlickEdit Inc. at 800 934-3348 or 919 473-0070.
    UPDATE_CANNOT_UPDATE_TRIAL_RC = -6810,
    // If this is a network installation:
    // 
    // This update should only be run by the network administrator.
    // Other users will automatically be updated.
    // 
    // Continue?
    UPDATE_NETWORK_INSTALL_RC = -6811,
    // To run this update, you will need to have 19MB of free space available on the partition where SlickEdit resides.
    // 
    // You currently have {0} bytes.
    // 
    // Please clear some space and try again
    UPDATE_INSUFFICIENT_DISK_SPACE_RC = -6812,
    // Update failed
    UPDATE_FAILED_RC = -6813,
    // Update complete
    UPDATE_COMPLETE_RC = -6814,
    // Path {0} does not exist or is incorrect
    UPDATE_PATH_DOES_NOT_EXIST_RC = -6815,
    // There does not appear to be a SlickEdit plugin in the path {0}.
    UPDATE_BAD_ECLIPSE_PATH = -6816,
    // Could not update the feature.xml file
    UPDATE_COULD_NOT_UPDATE_ECLIPSE_FEATURE_RC = -6817,
    // Could not update the .eclipseextension file
    UPDATE_COULD_NOT_UPDATE_ECLIPSE_EXTENSION_RC = -6818,
    // You will need to restart WebSphere Studio or Eclipse now
    UPDATE_RESTART_ECLIPSE_EXTENSION_RC = -6819,
    // Could not open file {0}
    UPDATE_CANNOT_OPEN_FILE_RC = -6820,
};
#endif

#ifndef VSMSGDEFS_FTP_H
#define VSMSGDEFS_FTP_H
enum VSMSGDEFS_FTP {
    // Bad or unexpected response
    VSRC_FTP_BAD_RESPONSE = -6851,
    // Connection lost
    VSRC_FTP_CONNECTION_DEAD = -6852,
    // Cannot stat file or directory
    VSRC_FTP_CANNOT_STAT = -6853,
    // Waiting for reply
    VSRC_FTP_WAITING_FOR_REPLY = -6854,
    // Bad or missing configuration
    VSRC_FTP_BAD_CONFIG = -6855,
    // Authentication failure
    VSRC_FTP_CANNOT_AUTHENTICATE = -6856,
    // reserve through 6899 for FTP
    VSRC_FTP_END_ERRORS = -6899,
};
#endif

#ifndef VSMSGDEFS_DELTASAVE_H
#define VSMSGDEFS_DELTASAVE_H
enum VSMSGDEFS_DELTASAVE {
    // Could not create archive file {0}
    DS_COULD_NOT_CREATE_ARCHIVE_FILE_RC = -6900,
    // Could not open archive file
    DS_ARCHIVE_FILE_NOT_OPEN_RC = -6901,
    // Source filename not set
    DS_SOURCE_FILENAME_NOT_SET_RC = -6902,
    // Version {0} of '{1}' not found
    DS_VERSION_NOT_FOUND_RC = -6903,
    // Pre-backup callback failed
    DS_PRE_CALLBACK_FAILED_RC = -6904,
    // Post-backup callback failed
    DS_POST_CALLBACK_FAILED_RC = -6905,
    // Files matched
    DS_FILE_MATCHED_RC = -6906,
    // A delta cannot be created because '{0}' is not the current file
    DS_NOT_CURRENT_BUFFER_RC = -6907,
    // The original encoding for the backup of this file ({0}) can no longer be used.
    // 
    // The file was opened using active code page
    DS_COULD_NOT_OPEN_FILE_WITH_CODE_PAGE_RC = -6908,
    // A delta cannot be created because '{0}' is in a directory which is excluded from backup history
    DS_FILE_EXCLUDED_RC = -6909,
    // The delta file's version could not be found
    DS_COULD_NOT_FIND_VERSION_RC = -6910,
    // Source file name not set
    DS_SOURCE_FILENAMNE_NOT_SET = -6911,
    // Cannot backup this file
    DS_CANNOT_BACKUP_THIS_FILE_RC = -6912,
    // Cannot replace most recent file {0} in backup history
    DS_CANNOT_REPLACE_MOST_RECENT_FILE_RC = -6913,
    // Cannot load most recent backup file for {0} in backup history
    DS_CANNOT_LOAD_BACKUP_MOST_RECENT_FILE_RC = -6914,
    // Could not create backup for file {0}: {1}
    DS_CANNOT_CREATE_BACKUP_FOR_FILE_RC =  -6915,
    // Invalid checksum for version {0} of source file {1} in archive file {2}.
    // 
    // Please contact SlickEdit support
    DS_INVALID_CHECKSUM_RC =  -6916,
    // Could not get checksum for version {0}
    DS_COULD_NOT_READ_ARCHIVE_FILE_RC =  -6917,
    // Version does not have checksum
    DS_VERSION_DOES_NOT_HAVE_CHECKSUM_RC =  -6918
};
#endif

#ifndef VSMSGDEFS_VSDIFF_H
#define VSMSGDEFS_VSDIFF_H
enum VSMSGDEFS_VSDIFF {
    // 
    // vsdiff
    // 
    // Usage:
    // 	To compare two files:
    // 	vsdiff  [-r1][-r2] [-wc <wildcard>] [-x <wildcard>] <FileOrPath1> <FileOrPath2>
    // 	If files have the same name, only give path for File2
    // 	ex:
    // 		vsdiff <path1>/file1.c <path2>
    // 	 +t Recurse directories (default)
    // 	 -t Do not recurse directories
    // 	 -r1 option will make file on left read only.
    // 	 -r2 option will make file on right read only.
    // 	 -wc <wildcard> for multi-file diff.  Multiple wildcards may be 
    // 		specified after -wc, separated by spaces.  Multiple
    // 		instances of -wc may be used.
    // 	 -x  <exclude wildcard> for multi-file diff.  Multiple wildcards 
    // 		may be specified after -x, separated by spaces.  Multiple
    // 		instances of -x may be used.
    // 	 -filelist [listfile] listfile is a relative list of filenames to be
    // 		diffed in the specified directories.
    // 	 -showdifferent Show different files
    // 	 -hidedifferent Hide different files
    // 	 -showmatching Show matching files
    // 	 -hidematching Hide matching files
    // 	 -shownotinpath1 Show files missing from path 1
    // 	 -hidenotinpath1 Hide files missing from path 1
    // 	 -shownotinpath2 Show files missing from path 2
    // 	 -hidenotinpath2 Hide files missing from path 2
    // 	 -showviewed Show files already viewed in diff
    // 	 -hideviewed Hide files already viewed in diff
    // 
    // 	To launch DIFFzilla(R) dialog:
    // 
    // 	vsdiff
    // 
    // 
    // 	A SlickEdit configuration path may be specified with a -sc option 
    // 	ex:
    // 		vsdiff -sc <configpath> ...
    VSDIFF_USAGE_RC = -7000,
    // vsdiff: could not find file "{0}"
    VSDIFF_FILE_NOT_FOUND_RC = -7001,
    // No more differences
    VSDIFF_NO_MORE_DIFFERENCES_RC = -7002,
    // No more conflicts
    VSDIFF_NO_MORE_CONFLICTS_RC = -7003,
    // vsdiff
    VSDIFF_APP_NAME = -7004,
    // No more differences.  Close now?
    VSDIFF_NO_MORE_DIFFERENCES_CLOSE_RC = -7005,
    // Diff timed out.  This is probably because not enough lines match.
    //
    // You can change the time out amount on the Options tab of the diff setup dialog.
    VSDIFF_TIMED_OUT_RC = -7006,
    // Cannot diff files because there are lines which exceed the length limit.
    // 
    // The length limit for a single line is 50MB.
    VSDIFF_LINE_TOO_LONG_RC = -7007,
    // Error hashing files
    VSDIFF_ERROR_HASHING_FILES_RC = -7008,
    // Diff not initialized
    VSDIFF_NOT_INTIALIZED = -7009,
    // Background diff already running
    VSDIFF_BACKGROUND_DIFF_ALREADY_RUNNING = -7010
};
#endif

#ifndef VSMSGDEFS_VSMERGE_H
#define VSMSGDEFS_VSMERGE_H
enum VSMSGDEFS_VSMERGE {
    // 
    // vsmerge
    // 
    // Usage:
    // 
    // vsmerge [options] <basefile> <revision1file> <revision2file> <outputfile>
    // 	options are as follows:
    // 		-smart:	Attempt to resolve simple conficts
    // 		-quiet:	Suppress "No conficts detected" message
    // 		-showchanges:	Force user to merge in non-conflict changes
    // 		-ignorespaces:	Ignore spaces in the files being merged
    // Usage:
    // 	To launch 3-way merge dialog:
    // 
    // 	vsmerge
    // 
    // 
    // 	A SlickEdit configuration path may be specified with a -sc option 
    // 	ex:
    // 		vsmerge -sc <configpath> ...
    VSMERGE_USAGE_RC = -7100,
    // vsmerge: Could not find file "{0}"
    VSMERGE_FILE_NOT_FOUND_RC = -7101,
    // vsmerge
    VSMERGE_APP_NAME = -7102,
    // vsmerge: Invalid option "{0}"
    VSMERGE_INVALID_OPTION_RC = -7103,
};
#endif

#ifndef VSMSGDEFS_VSMFUNDO_H
#define VSMSGDEFS_VSMFUNDO_H
enum VSMSGDEFS_VSMFUNDO {
    // Multi file undo stack empty
    VSRC_MFUNDO_STACK_EMPTY = -7200,
    // Multi file undo step has already been ended
    VSRC_MFUNDO_STEP_ALREADY_ENDED = -7201,
    // vsMFUndoEndStep() not called to generate redo information
    VSRC_MFUNDO_END_STEP_NOT_CALLED = -7202,
    // Failed to generate redo information
    VSRC_FAILED_TO_GENERATE_REDO_INFO = -7203,
    // vsMFUndoBegin() not called
    VSRC_MFUNDO_BEGIN_NOT_CALLED = -7204,
    // vsMFUndoBeginStep() not called
    VSRC_MFUNDO_BEGIN_STEP_NOT_CALLED = -7205,
};
#endif

#ifndef VSMSGDEFS_VSREFACTOR_H
#define VSMSGDEFS_VSREFACTOR_H
enum VSMSGDEFS_VSREFACTOR {
    // Could not find parser configuration:  '{0}'
    VSRC_VSREFACTOR_CONFIGURATION_NOT_FOUND_1A = -7500,
    // Refactoring configuration file not open
    VSRC_VSREFACTOR_CONFIGURATION_FILE_NOT_OPEN = -7501,
    // Invalid refactoring transaction handle
    VSRC_VSREFACTOR_TRANSACTION_HANDLE_INVALID = -7502,
    // internal error
    VSRC_VSREFACTOR_INTERNAL_ERROR = -7503,
    // Could not find symbol:  '{0}'
    VSRC_VSREFACTOR_SYMBOL_NOT_FOUND_1A = -7504,
    // Invalid symbol for this operation:  '{0}'
    VSRC_VSREFACTOR_INVALID_SYMBOL_1A = -7505,
    // Invalid include path
    VSRC_VSREFACTOR_INVALID_INCLUDE_PATH = -7506,
    // Invalid #define/#undef
    VSRC_VSREFACTOR_INVALID_DEFINE = -7507,
    // Invalid configuration file
    VSRC_VSREFACTOR_INVALID_CONFIGURATION_FILE = -7508,
    // This reference to the refactored method can not resolve an instance
    VSRC_VSREFACTOR_STATIC_TO_INSTANCE_METHOD_WARNING = -7509,
    // Cannot replace the selected code block with a function call.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_CALL = -7510,
    // A declaration within the selected code block calls a class constructor.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_CONSTRUCTOR = -7511,
    // The selected code block contains a goto statement.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_GOTO = -7512,
    // The selected code block contains a return statement.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_RETURN = -7513,
    // The selected code block contains a break statement.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_BREAK = -7514,
    // The selected code block contains a continue statement.
    VSRC_VSREFACTOR_CANNOT_REPLACE_CODE_WITH_CONTINUE = -7515,
    // {0} errors found parsing.  Please see the Output Toolbar for details.
    VSRC_VSREFACTOR_PARSING_FAILURE_1A = -7516,
    // Please wait...
    VSRC_VSREFACTOR_PLEASE_WAIT = -7517,
    // Analyzing...
    VSRC_VSREFACTOR_ANALYZING = -7518,
    // Processing Templates...
    VSRC_VSREFACTOR_PROCESSING_TEMPLATES = -7519,
    // Parsing...
    VSRC_VSREFACTOR_PARSING = -7520,
    // File:  {0}
    VSRC_VSREFACTOR_FILE_1A = -7521,
    // File {1}/{2}:  {0}
    VSRC_VSREFACTOR_FILE_3A = -7522,
    // Refactoring...
    VSRC_VSREFACTOR_REFACTORING = -7523,
    // Finding modified files...
    VSRC_VSREFACTOR_FINDING_MODIFIED = -7524,
    // Saving...
    VSRC_VSREFACTOR_SAVING = -7525,
    // Cleaning up...
    VSRC_VSREFACTOR_CLEANING_UP = -7526,
    // This reference is not a class.
    VSRC_VSREFACTOR_SYMBOL_IS_NOT_A_CLASS = -7527,
    // The file to move the static definition to does not exist.
    VSRC_VSREFACTOR_CLASS_DEFINITION_FILE_DOES_NOT_EXIST = -7528,
    // There is already a symbol named '{0}'
    VSRC_VSREFACTOR_SYMBOL_ALREADY_DEFINED_1A = -7529,
    // The symbol '{0}' is not a function.
    VSRC_VSREFACTOR_SYMBOL_IS_NOT_A_FUNCTION_1A = -7530,
    // Modified function conflicts with an already existing overloaded function
    VSRC_VSREFACTOR_FUNCTION_CONFLICT = -7531,
    // New parameter name matches the name of a variable in the function context
    VSRC_VSREFACTOR_NEW_PARAMETER_CONFLICT = -7532,
    // The symbol is not a member of a class.
    VSRC_VSREFACTOR_NOT_A_CLASS_MEMBER = -7533,
    // The symbol '{0}' would be hidden by moving it to this super class.
    VSRC_VSREFACTOR_SYMBOL_WOULD_BE_HIDDEN_1A = -7534,
    // Preprocessing...
    VSRC_VSREFACTOR_PREPROCESSING = -7535,
    // Unexpected compiler configuration type encountered.
    VSRC_VSREFACTOR_CONFIGURATION_UNEXPECTED_TYPE = -7535,
    // reserve through 7999 for VSREFACTOR
    VSRC_VSREFACTOR_END_ERRORS = -7999,
};
#endif

#ifndef VSMSGDEFS_VSPARSER_H
#define VSMSGDEFS_VSPARSER_H
enum VSMSGDEFS_VSPARSER {
    // {0}({1},{2}): error {3}: 
    VSRC_VSPARSER_ERROR_PREFIX = -8000,
    // syntax error '{0}'
    VSRC_VSPARSER_SYNTAX_ERROR_1A = -8001,
    // expecting '{0}'
    VSRC_VSPARSER_EXPECTING_1A = -8002,
    // attempt to recover after last error failed.
    VSRC_VSPARSER_RECOVER_FAILED = -8003,
    // expecting identifier
    VSRC_VSPARSER_EXPECTING_IDENTIFIER = -8004,
    // expecting newline
    VSRC_VSPARSER_EXPECTING_NEWLINE = -8005,
    // unrecognized character
    VSRC_VSPARSER_UNRECOGNIZED_CHARACTER = -8006,
    // unterminated block comment
    VSRC_VSPARSER_UNTERMINATED_COMMENT = -8007,
    // unterminated string or character constant
    VSRC_VSPARSER_UNTERMINATED_STRING = -8008,
    // malformed numeric literal
    VSRC_VSPARSER_MALFORMED_NUMBER = -8009,
    // unexpected token: '{0}'
    VSRC_VSPARSER_UNEXPECTED_TOKEN_1A = -8010,
    // expecting number
    VSRC_VSPARSER_EXPECTING_NUMBER = -8011,
    // expecting argument name
    VSRC_VSPARSER_EXPECTING_ARGUMENT = -8012,
    // {0} without matching {1}
    VSRC_VSPARSER_MISMATCHED_GROUP_2A = -8013,
    // unrecognized identifier: '{0}'
    VSRC_VSPARSER_UNRECOGNIZED_IDENTIFIER_1A = -8014,
    // {0}({1},{2}): warning {3}: 
    VSRC_VSPARSER_WARNING_PREFIX = -8015,
    // reuse of macro formal parameter '{0}'
    VSRC_VSPARSER_REUSE_OF_MACRO_PARAMETER_1A = -8016,
    // redefinition of macro '{0}'
    VSRC_VSPARSER_MACRO_REDEFINITION_1A = -8017,
    // see previous definition of '{0}'
    VSRC_VSPARSER_SEE_PREVIOUS_DEFINITION_1A = -8018,
    // see definition of '{0}'
    VSRC_VSPARSER_SEE_DEFINITION_1A = -8019,
    // undefined symbol '{0}'
    VSRC_VSPARSER_SYMBOL_NOT_FOUND_1A = -8020,
    // internal error
    VSRC_VSPARSER_INTERNAL_ERROR = -8021,
    // cannot add two pointers
    VSRC_VSPARSER_CANNOT_ADD_TWO_POINTERS = -8022,
    // no '{0}' operator defined which matches the operands
    VSRC_VSPARSER_NO_SUCH_OPERATOR_1A = -8023,
    // incomplete expression
    VSRC_VSPARSER_INCOMPLETE_EXPRESSION = -8024,
    // array index must have integral type
    VSRC_VSPARSER_INVALID_ARRAY_INDEX = -8025,
    // operands to the '{0}' operator must have integral types
    VSRC_VSPARSER_INTEGRAL_TYPE_EXPECTED_1A = -8026,
    // expecting modifiable lvalue
    VSRC_VSPARSER_EXPECTING_LVALUE = -8027,
    // cannot assign from '{0}' to '{1}' -- types are incompatible and there is no suitable conversion
    VSRC_VSPARSER_CANNOT_ASSIGN_TO_2A = -8028,
    // conversion may result in loss of precision
    VSRC_VSPARSER_LOSS_OF_PRECISION = -8029,
    // types are incompatible or can not be converted unambiguously
    VSRC_VSPARSER_TYPES_ARE_INCOMPATIBLE = -8030,
    // expecting a pointer type
    VSRC_VSPARSER_EXPECTING_POINTER_TYPE = -8031,
    // operator '.' used where '->' was expected
    VSRC_VSPARSER_UNEXPECTED_POINTER_TYPE = -8032,
    // expecting class, struct, or union type
    VSRC_VSPARSER_EXPECTING_CLASS_TYPE = -8033,
    // constant expression results in division by zero
    VSRC_VSPARSER_DIVISION_BY_ZERO = -8034,
    // operator '%' can not be applied to floating point operands
    VSRC_VSPARSER_CANNOT_MODULO_FLOAT = -8035,
    // expecting pointer to member
    VSRC_VSPARSER_POINTER_TO_MEMBER_EXPECTED = -8036,
    // could not calculate size of expression.
    VSRC_VSPARSER_COULD_NOT_CALCULATE_SIZE = -8037,
    // expecting integral type
    VSRC_VSPARSER_EXPECTING_INTEGRAL_TYPE = -8038,
    // expecting constant expression
    VSRC_VSPARSER_EXPECTING_CONSTANT_EXPRESSION = -8039,
    // initializer not allowed
    VSRC_VSPARSER_INITIALIZER_NOT_ALLOWED = -8040,
    // symbol '{0}' is already defined
    VSRC_VSPARSER_SYMBOL_ALREADY_DEFINED_1A = -8041,
    // same type qualifier used more than once
    VSRC_VSPARSER_REPEATED_QUALIFIER = -8042,
    // cannot convert from '{0}' to '{1}'
    VSRC_VSPARSER_CANNOT_CONVERT_TYPE_2A = -8043,
    // function must return a value
    VSRC_VSPARSER_FUNCTION_MUST_RETURN_VALUE = -8044,
    // static member functions do not have 'this' pointer
    VSRC_VSPARSER_THIS_NOT_ALLOWED = -8045,
    // expecting template name
    VSRC_VSPARSER_EXPECTING_TEMPLATE = -8046,
    // invalid template argument '{0}'
    VSRC_VSPARSER_INCOMPATIBLE_TEMPLATE_ARGUMENT_1A = -8047,
    // references cannot be created by new-expressions
    VSRC_VSPARSER_CANNOT_NEW_REFERENCE_TYPE = -8048,
    // '{0}' is not a namespace identifier
    VSRC_VSPARSER_EXPECTING_NAMESPACE_1A = -8049,
    // cannot access private member '{0}' from this scope
    VSRC_VSPARSER_PRIVATE_MEMBER_1A = -8050,
    // cannot access protected member '{0}' from this scope
    VSRC_VSPARSER_PROTECTED_MEMBER_1A = -8051,
    // pure virtual specifier applies only to virtual functions
    VSRC_VSPARSER_PURE_BUT_NOT_VIRTUAL = -8052,
    // inline specifier applies only to functions
    VSRC_VSPARSER_INLINE_BUT_NOT_FUNCTION = -8053,
    // virtual specifier applies only to functions
    VSRC_VSPARSER_VIRTUAL_BUT_NOT_FUNCTION = -8054,
    // explicit specifier applies only to constructors
    VSRC_VSPARSER_EXPLICIT_BUT_NOT_CONSTRUCTOR = -8055,
    // virtual specifier not allowed for a constructor
    VSRC_VSPARSER_VIRTUAL_CONSTRUCTOR = -8056,
    // constructors, destructors, and conversion operators are not allowed to have return types
    VSRC_VSPARSER_RETURN_TYPE_NOT_ALLOWED = -8057,
    // '{0}' is not static
    VSRC_VSPARSER_EXPECTING_STATIC_MEMBER_1A = -8058,
    // void function cannot return a value
    VSRC_VSPARSER_FUNCTION_CANNOT_RETURN_VALUE = -8059,
    // static specifier can not be used with virtual
    VSRC_VSPARSER_STATIC_AND_VIRTUAL = -8060,
    // initializer list not allowed for '{0}'
    VSRC_VSPARSER_INITIALIZER_LIST_NOT_ALLOWED_1A = -8061,
    // too many initializer expressions
    VSRC_VSPARSER_TOO_MANY_INITIALIZERS = -8062,
    // ambiguous call to overloaded function '{0}'
    VSRC_VSPARSER_AMBIGUOUS_FUNCTION_CALL_1A = -8063,
    // function '{0}' does not take {1} arguments
    VSRC_VSPARSER_FUNCTION_WRONG_NUMBER_ARGUMENTS_2A = -8064,
    // too many arguments
    VSRC_VSPARSER_TOO_MANY_ARGUMENTS = -8065,
    // no default argument
    VSRC_VSPARSER_NO_DEFAULT_ARGUMENT = -8066,
    // argument lists do not match
    VSRC_VSPARSER_ARGUMENT_LISTS_DO_NOT_MATCH = -8067,
    // template '{0}' does not take {1} arguments
    VSRC_VSPARSER_TEMPLATE_WRONG_NUMBER_ARGUMENTS_2A = -8068,
    // template '{0}' was instantiated before it was specialized
    VSRC_VSPARSER_TEMPLATE_INSTANTIATED_BEFORE_SPECIALIZATION_1A = -8069,
    // template '{0}' instantiated with a forward declared type
    VSRC_VSPARSER_TEMPLATE_INSTANTIATED_WITH_FORWARD_DECLARED_TYPE_1A = -8070,
    // unable to determine type of template argument '{1}' in template '{0}'
    VSRC_VSPARSER_TEMPLATE_UNABLE_TO_DETERMINE_ARGUMENTS_2A = -8071,
    // detected possible recursive or mutually recursive include file(s): '{0}'
    VSRC_VSPARSER_RECURSIVELY_INCLUDED_HEADER_FILE_1A = -8072,
    // switch statement contains more than one default case
    VSRC_VSPARSER_SWITCH_HAS_MORE_THAN_ONE_DEFAULT = -8073,
    // incomplete type information
    VSRC_VSPARSER_INCOMPLETE_TYPE_INFO = -8074,
    // line comment has line continuation
    VSRC_VSPARSER_LINE_COMMENT_HAS_CONTINUATION = -8075,
    // '{0}' is not a member of '{1}'
    VSRC_VSPARSER_NOT_A_MEMBER_OF_2A = -8076,
    // switch statement contains no cases or default
    VSRC_VSPARSER_SWITCH_HAS_NO_CASE_OR_DEFAULT = -8077,
    // internal error: {0}.{1}
    VSRC_VSPARSER_INTERNAL_ERROR_2A = -8078,
    // preprocessing expanded from here
    VSRC_VSPARSER_PREPROCESSING_LOCATION = -8079,
    // redefinition of default value for parameter '{0}'
    VSRC_VSPARSER_DEFAULT_VALUE_REDEFINITION_1A = -8080,
    // try statement requires at least one handler statement
    VSRC_VSPARSER_TRY_REQUIRES_HANDLER = -8081,
    // pointer arithmetic requires integral type on right
    VSRC_VSPARSER_POINTER_ARITHMETIC_REQUIRES_INTEGRAL_TYPE = -8082,
    // template parameter '{1}' in template '{0}' is ambiguous
    VSRC_VSPARSER_TEMPLATE_PARAMETER_AMBIGUOUS_2A = -8083,
    // variable length array dimensions can not be used in this context
    VSRC_VSPARSER_VARIABLE_LENGTH_ARRAYS_NOT_ALLOWED_HERE = -8084,
    // 'void' cannot be an argument type, except for '(void)'
    VSRC_VSPARSER_VOID_ILLEGALLY_USED_AS_ARGUMENT_TYPE = -8085,
    // cannot assign from '{0}' to '{1}' -- left hand side specifies const object
    VSRC_VSPARSER_CANNOT_ASSIGN_TO_CONST_2A = -8086,
    // mutable specifier can not be used with const
    VSRC_VSPARSER_MUTABLE_AND_CONST = -8087,
    // cannot assign to const object of type '{0}'
    VSRC_VSPARSER_CANNOT_INCREMENT_CONST_1A = -8088,
    // cannot use const or volatile modifiers on a function outside of a class declaration
    VSRC_VSPARSER_CANNOT_USE_CONST_OR_VOLATILE_OUTSIDE_OF_CLASS = -8089,
    // reserve through 8999 for VSPARSER
    VSRC_VSPARSER_END_ERRORS = -8999,
};
#endif

#ifndef VSMSGDEFS_UPCHECK_H
#define VSMSGDEFS_UPCHECK_H
enum VSMSGDEFS_UPCHECK {
    // 
    // Update Check Version {0}
    // 
    // This program is used to check for and retrieve product updates.
    // 
    // Usage: {1} [-help] [-proxy hostname:port] [-noproxy] [-i] [-updatebase base] [-c command]
    // where:
    // 	-help     	Display this message.
    // 	-i            	Interactive mode.
    // 	-updatebase 	HTTP base url for fetching updates (do NOT include 'http://').
    // 	-proxy   	Use HTTP proxy at hostname on port.
    // 	-noproxy 	Windows only. Do not use Internet Explorer proxy/connection settings.
    // 	-c           	Execute command then exit. If given, this must be the last argument.
    // 
    VSRC_UPCHECK_HELP = -9000,
    // Unknown command '{0}'
    VSRC_UPCHECK_UNKNOWN_COMMAND = -9001,
    // Invalid option '{0}'
    VSRC_UPCHECK_INVALID_ARGUMENT = -9002,
    // Error opening output file: '{0}'
    VSRC_UPCHECK_ERROR_OPENING_OUTPUT_FILE = -9003,
    // Not enough arguments. {0}
    VSRC_UPCHECK_NOT_ENOUGH_ARGUMENTS = -9004,
    // Action failed for '{0}': {1}
    VSRC_UPCHECK_ACTION_FAILED = -9005,
    // Missing status for action '{0}'
    VSRC_UPCHECK_MISSING_ACTION_STATUS = -9006,
    // Missing 'upcheck' command at location '{0}'
    VSRC_UPCHECK_NOT_FOUND = -9007,
    // Error starting 'upcheck' command
    VSRC_UPCHECK_ERROR_STARTING = -9008,
    // Timed out waiting for reply
    VSRC_UPCHECK_TIMED_OUT = -9009,
    // Invalid response
    VSRC_UPCHECK_INVALID_RESPONSE = -9010,
    // Version not supported: {0}
    VSRC_UPCHECK_VERSION_NOT_SUPPORTED = -9011,
    // Error creating upcheck log
    VSRC_UPCHECK_ERROR_CREATING_LOG = -9012,
    // Error saving manifest file '{0}'
    VSRC_UPCHECK_ERROR_SAVING_MANIFEST = -9013,
    // Error retrieving updates
    VSRC_UPCHECK_ERROR_RETRIEVING_UPDATES = -9014,
    // You can check for new updates anytime from the Help>Product Updates menu
    VSRC_UPCHECK_MANUAL_CHECK_HELP = -9015,
};
#endif

#ifndef VSMSGDEFS_VSRTE_H
#define VSMSGDEFS_VSRTE_H
enum VSMSGDEFS_VSRTE {
    // Unable to load JVM library
    RTE_CANT_LOAD_JVM_LIB = -9100,
    // Unable to find JVM creation function
    RTE_CANT_FIND_CREATE_VM = -9101,
    // No JVM found for RTE
    RTE_NO_JVM = -9102,
    // Cannot attach current thread to the JVM
    RTE_CANT_ATTACH = -9103,
    // Cannot create JVM environment
    RTE_CANT_CREATE_ENV = -9104,
    // Cannot find RTE compiler
    RTE_CANT_FIND_COMPILER_CLASS = -9105,
    // Cannot find constructor for RTE compiler class
    RTE_CANT_FIND_CONSTRUCTOR = -9106,
    // Cannot instantiate RTE compiler class
    RTE_CANT_INSTANTIATE_CLASS = -9107,
    // Failure creating jstring
    RTE_CANT_CREATE_JSTRING = -9108,
    // Cannot locate RTE compiler method
    RTE_CANT_FIND_COMPILE_ID = -9109,
    // Failure retrieving errors from Java
    RTE_CANT_GET_ERRORS = -9110,
    // Live Error
    RTE_MESSAGE_TYPE = -9111,
    // Invalid number of arguments specified for Javac option
    RTE_INVALID_ARGS_FOR_OPTION = -9112,
    // reserved through 9200 for RTE
    RTE_END_ERRORS = -9200,
};
#endif

#ifndef VSMSGDEFS_DBGP_H
#define VSMSGDEFS_DBGP_H
enum VSMSGDEFS_DBGP {
    // DBGP error: No error has occurred
    DBGP_ERROR_NONE_RC = -9201,
    // DBGP error: Parse error in command
    DBGP_ERROR_PARSE_RC = -9203,
    // DBGP error: Duplicate arguments in command
    DBGP_ERROR_DUPLICATE_ARGS_RC = -9204,
    // DBGP error: Invalid options
    DBGP_ERROR_INVALID_OPTIONS_RC = -9205,
    // DBGP error: Unimplemented command
    DBGP_ERROR_UNIMPLEMENTED_RC = -9206,
    // DBGP error: Command not available
    DBGP_ERROR_COMMAND_NOT_AVAILABLE_RC = -9207,
    // DBGP error: Can not open file
    DBGP_ERROR_OPENING_FILE_RC = -9208,
    // DBGP error: Stream redirect failed
    DBGP_ERROR_STREAM_REDIRECT_FAILED_RC = -9209,
    // DBGP error: Breakpoint could not be set
    DBGP_ERROR_BREAKPOINT_NOT_SET_RC = -9210,
    // DBGP error: Breakpoint type not supported
    DBGP_ERROR_BREAKPOINT_NOT_SUPPORTED_RC = -9211,
    // DBGP error: Invalid breakpoint
    DBGP_ERROR_BREAKPOINT_INVALID_RC = -9212,
    // DBGP error: No code on breakpoint line
    DBGP_ERROR_BREAKPOINT_NO_CODE_RC = -9213,
    // DBGP error: Invalid breakpoint state
    DBGP_ERROR_BREAKPOINT_INVALID_STATE_RC = -9214,
    // DBGP error: No such breakpoint
    DBGP_ERROR_BREAKPOINT_NOT_EXIST_RC = -9215,
    // DBGP error: Error evaluating code
    DBGP_ERROR_EVAL_RC = -9216,
    // DBGP error: Invalid expression
    DBGP_ERROR_EXPR_RC = -9217,
    // DBGP error: Can not get property
    DBGP_ERROR_INVALID_PROPERTY_RC = -9218,
    // DBGP error: Stack depth invalid
    DBGP_ERROR_INVALID_STACK_DEPTH_RC = -9219,
    // DBGP error: Context invalid
    DBGP_ERROR_INVALID_CONTEXT_RC = -9220,
    // DBGP error: Encoding not supported
    DBGP_ERROR_ENCODING_NOT_SUPPORTED_RC = -9221,
    // DBGP error: An internal exception in the debugger occurred
    DBGP_ERROR_INTERNAL_EXCEPTION_RC = -9222,
    // DBGP error: Unknown error
    DBGP_ERROR_UNKNOWN_RC = -9223,
    // reserved through 9300 for DBGP
    DBGP_END_ERRORS = -9300,
};
#endif

#ifndef VSMSGDEFS_WINDBG_H
#define VSMSGDEFS_WINDBG_H
enum VSMSGDEFS_WINDBG {
    // WINDBG error: None
    WINDBG_ERROR_NONE_RC = -9301,
    // Initialization failed
    WINDBG_ERROR_INIT_FAILED = -9302,
    // CreateProcess failed
    WINDBG_ERROR_CREATE_PROCESS_RC = -9303,
    // AttachProcess failed
    WINDBG_ERROR_ATTACH_PROCESS_RC = -9304,
    // OpenDumpFile failed
    WINDBG_ERROR_OPEN_DUMP_FILE_RC = -9305,
    // WriteDumpFile failed
    WINDBG_ERROR_WRITE_DUMP_FILE_RC = -9306,
    // DetachProcesses failed
    WINDBG_ERROR_DETACH_PROCESS_RC = -9307,
    // TerminateProcesses failed
    WINDBG_ERROR_TERMINATE_PROCESS_RC = -9308,
    // Error resuming the application
    WINDBG_ERROR_RESUMING_RC = -9309,
    // Error suspending the application
    WINDBG_ERROR_SUSPENDING_RC = -9310,
    // SetExecutionStatus failed
    WINDBG_ERROR_EXECUTION_STATUS_RC = -9311,
    // GetNumberThreads failed
    WINDBG_ERROR_GET_THREADS_RC = -9312,
    // GetCurrentThreadId failed
    WINDBG_ERROR_GET_CURRENT_THREAD_RC = -9313,
    // SetCurrentThreadId failed
    WINDBG_ERROR_SET_CURRENT_THREAD_RC = -9314,
    // GetNumberRegisters failed
    WINDBG_ERROR_GET_REGISTERS_RC = -9315,
    // Evaluate failed
    WINDBG_ERROR_EVALUATE_RC = -9316,
    // ReadVirtual failed
    WINDBG_ERROR_GET_MEMORY_RC = -9317,
    // GetStackTrace failed
    WINDBG_ERROR_GET_STACK_RC = -9318,
    // SetScope failed
    WINDBG_ERROR_SET_SCOPE_RC = -9319,
    // GetLocals failed
    WINDBG_ERROR_GET_LOCALS_RC = -9320,
    // Modify variable failed
    WINDBG_ERROR_MODIFY_VAR_RC = -9321,
    // GetThis failed
    WINDBG_ERROR_GET_THIS_RC = -9322,
    // EnableBreakpoint failed
    WINDBG_ERROR_ENABLE_BREAKPOINT_RC = -9323,
    // Evaluate breakpoint failed
    WINDBG_ERROR_EVALUATE_BREAKPOINT_RC = -9324,
    // CreateSymbolGroup failed
    WINDBG_ERROR_SYMBOLGROUP_RC = -9325,
    // GetSymbolName failed
    WINDBG_ERROR_SYMBOL_NAME_RC = -9326,
    // GetSymbolTypeName failed
    WINDBG_ERROR_SYMBOL_TYPENAME_RC = -9327,
    // GetSymbolParameters failed
    WINDBG_ERROR_SYMBOL_PARAMETERS_RC = -9328,
    // ExpandSymbol failed
    WINDBG_ERROR_EXPAND_VAR_RC = -9329,
    // GetOffsetByLine failed
    WINDBG_ERROR_GET_OFFSET_LINE_RC = -9330,
    // No more events
    WINDBG_NO_MORE_EVENTS_RC = -9331,
    // Failed to load dbgeng.dll
    WINDBG_ERROR_DBGENG_FAILED_RC = -9332,
    // WriteSymbol failed
    WINDBG_ERROR_WRITESYMBOL_FAILED_RC = -9333,
    // DebugCreate failed
    WINDBG_ERROR_DEBUGCREATE_FAILED_RC = -9334,
    // QueryInterface failed
    WINDBG_ERROR_QUERY_FAILED_RC = -9335,
    // AddSymbolGroup failed
    WINDBG_ERROR_ADDSYMBOLGROUP_RC = -9336,
    // SetWatch failed
    WINDBG_ERROR_WATCH_RC = -9337,
    // GetGroup failed
    WINDBG_ERROR_GET_GROUP_RC = -9338,
    // Invalid debugger args
    WINDBG_INVALID_DEBUGGER_ARGS_RC = -9339,
    // Symbol evaluation timed out
    WINDBG_SYMBOL_TIMED_OUT_RC = -9340,
    // Unsupported
    WINDBG_ERROR_UNSUPPORTED_RC = -9341,
    // reserved through 9400 for WINDBG
    WINDBG_END_ERRORS = -9400,
};
#endif

#ifndef VSMSGDEFS_MONO_H
#define VSMSGDEFS_MONO_H
enum VSMSGDEFS_MONO {
    // Mono SDWF: Success (no error)
    MONO_ERROR_SUCCESS_RC                   = -10000,
    // Mono SDWF error: Passed object is invalid or has been unloaded and garbage collected 
    MONO_ERROR_INVALID_OBJECT_RC            = -10020,
    // Mono SDWF error: Invalid field ID
    MONO_ERROR_INVALID_FIELD_ID_RC          = -10025,
    // Mono SDWF error: Invalid frame ID
    MONO_ERROR_INVALID_FRAME_ID_RC          = -10030,
    // Mono SDWF error: Feature not implemented in this virtual machine
    MONO_ERROR_NOT_IMPLEMENTED_RC           = -10100,
    // Mono SDWF error: Thread not suspended
    MONO_ERROR_NOT_SUSPENDED_RC             = -10101,
    // Mono SDWF error: Invalid argument 
    MONO_ERROR_INVALID_ARGUMENT_RC          = -10102,
    // Mono SDWF error: AppDomain has been unloaded
    MONO_ERROR_UNLOADED_RC                  = -10103,
    // Mono SDWF error: Trying to abort a thread which is not in a runtime invocation
    MONO_ERROR_NO_INVOCATION_RC             = -10104,
    // Mono SDWF error: A requested method debug information is not available
    MONO_ERROR_ABSENT_INFORMATION_RC        = -10105,
    // Mono SDWF error: Breakpoint could not be set at offset
    MONO_ERROR_NO_SEQ_POINT_AT_IL_OFFSET_RC = -10106,
};
#endif


#ifndef VSMSGDEFS_MACRO_H
#define VSMSGDEFS_MACRO_H
enum VSMSGDEFS_MACRO {
    // Command Line
    VSRC_FCF_ELEMENTS_COMMAND_LINE = -101100,
    // Status Line
    VSRC_FCF_ELEMENTS_STATUS_LINE = -101101,
    // SBCS/DBCS Source Windows
    VSRC_FCF_ELEMENTS_SBCS_DBCS_SOURCE_WINDOWS = -101102,
    // Hex Source Windows
    VSRC_FCF_ELEMENTS_HEX_SOURCE_WINDOWS = -101103,
    // Unicode Source Windows
    VSRC_FCF_ELEMENTS_UNICODE_SOURCE_WINDOWS = -101104,
    // File Manager Windows
    VSRC_FCF_ELEMENTS_FILE_MANAGER_WINDOWS = -101105,
    // Parameter Information
    VSRC_FCF_ELEMENTS_PARAMETER_INFO = -101106,
    // Parameter Information Fixed
    VSRC_FCF_ELEMENTS_PARAMETER_INFO_FIXED = -101107,
    // Selection List
    VSRC_FCF_ELEMENTS_SELECTION_LIST = -101108,
    // Menu
    VSRC_FCF_ELEMENTS_MENU = -101109,
    // Dialog
    VSRC_FCF_ELEMENTS_DIALOG = -101110,
    // MDI Child Icon
    VSRC_FCF_ELEMENTS_MDI_CHILD_ICON = -101111,
    // MDI Child Title
    VSRC_FCF_ELEMENTS_MDI_CHILD_TITLE = -101112,
    // Diff Editor SBCS/DBCS Source Windows
    VSRC_FCF_ELEMENTS_DIFF_EDITOR_WINDOWS = -101113,
    // HTML Proportional
    VSRC_FCF_ELEMENTS_MINIHTML_PROPORTIONAL = -101114,
    // HTML Fixed
    VSRC_FCF_ELEMENTS_MINIHTML_FIXED = -101115,
    // Document Tabs
    VSRC_FCF_ELEMENTS_DOCUMENT_TABS = -101116,
    // Diff Editor Unicode Source Windows
    VSRC_FCF_ELEMENTS_UNICODE_DIFF_EDITOR_WINDOWS = -101117,
    // Block Comment
    VSRC_CFG_COMMENT = -101120,
    // Current Line
    VSRC_CFG_CURRENT_LINE = -101121,
    // Cursor
    VSRC_CFG_CURSOR = -101122,
    // No Save Line
    VSRC_CFG_NOSAVE_LINE = -101123,
    // Inserted Line
    VSRC_CFG_INSERTED_LINE = -101124,
    // Keyword
    VSRC_CFG_KEYWORD = -101125,
    // Line Number
    VSRC_CFG_LINE_NUMBER = -101126,
    // Line Prefix Area
    VSRC_CFG_LINE_PREFIX_AREA = -101127,
    // Message
    VSRC_CFG_MESSAGE = -101128,
    // Modified Line
    VSRC_CFG_MODIFIED_LINE = -101129,
    // Number
    VSRC_CFG_NUMBER = -101130,
    // Preprocessor
    VSRC_CFG_PREPROCESSOR = -101131,
    // Selected Current Line
    VSRC_CFG_SELECTED_CURRENT_LINE = -101132,
    // Selection
    VSRC_CFG_SELECTION = -101133,
    // Status
    VSRC_CFG_STATUS = -101134,
    // String
    VSRC_CFG_STRING = -101135,
    // Window Text
    VSRC_CFG_WINDOW_TEXT = -101136,
    // Punctuation
    VSRC_CFG_PUNCTUATION = -101137,
    // Library Symbol
    VSRC_CFG_LIBRARY_SYMBOL = -101138,
    // Operator
    VSRC_CFG_OPERATOR = -101139,
    // User Defined Keyword
    VSRC_CFG_USER_DEFINED_SYMBOL = -101140,
    // Function
    VSRC_CFG_FUNCTION = -101141,
    // Filename
    VSRC_CFG_FILENAME = -101142,
    // Highlight
    VSRC_CFG_HIGHLIGHT = -101143,
    // Attribute
    VSRC_CFG_ATTRIBUTE = -101144,
    // Unknown Tag/Element
    VSRC_CFG_UNKNOWN_TAG = -101145,
    // XHTML Element in XSL
    VSRC_CFG_XHTML_ELEMENT_IN_XSL = -101146,
    // Active Tool Window Caption
    VSRC_CFG_ACTIVE_TOOL_WINDOW_CAPTION = -101147,
    // Inactive Tool Window Caption
    VSRC_CFG_INACTIVE_TOOL_WINDOW_CAPTION = -101148,
    // Line Comment
    VSRC_CFG_LINE_COMMENT = -101149,
    // Unable to open system color scheme file.
    VSRC_CFG_UNABLE_TO_OPEN_SYSTEM_COLOR_SCHEME = -101150,
    // The current color scheme has been modified.  Are you sure you want to discard the changes?
    VSRC_CFG_COLOR_SCHEME_MODIFIED = -101151,
    // There is no active color scheme to rename.
    VSRC_CFG_NO_ACTIVE_SCHEME_TO_RENAME = -101152,
    // File {0} not found.
    VSRC_CFG_FILE_NOT_FOUND = -101153,
    // Error reading {0}.
    VSRC_CFG_ERROR_READING_FILE = -101154,
    // Cannot find user scheme: {0}.  System schemes cannot be renamed.
    VSRC_CFG_CANNOT_FIND_USER_SCHEME = -101155,
    // Invalid scheme name.
    VSRC_CFG_INVALID_SCHEME_NAME = -101156,
    // A scheme with this name already exists.
    VSRC_CFG_SCHEME_ALREADY_EXISTS = -101157,
    // Unable to save file {0}.
    VSRC_CFG_UNABLE_TO_SAVE = -101158,
    // There is no active color scheme to remove.
    VSRC_CFG_NO_ACTIVE_SCHEME_TO_REMOVE = -101159,
    // Unable to remove scheme: {0}.  It does not exist.
    VSRC_CFG_UNABLE_TO_REMOVE = -101160,
    // System schemes cannot be removed.
    VSRC_CFG_CANNOT_REMOVE_SYSTEM_SCHEMES = -101161,
    // Are you sure you want to remove this scheme: {0}?
    VSRC_CFG_REMOVE_SCHEME_CONFIRMATION = -101162,
    // Rename Scheme
    VSRC_CFG_RENAME_SCHEME = -101163,
    // Rename To
    VSRC_CFG_RENAME_TO = -101164,
    // RGB values must be between 0 and 255.
    VSRC_CFG_RGB_VALUES_RANGE_WARNING = -101165,
    // Invalid color.  Unable to update sample.
    VSRC_CFG_INVALID_COLOR = -101166,
    // Please specify a name for the color scheme.
    VSRC_CFG_SPECIFY_COLOR_SCHEME_NAME = -101167,
    // Color scheme name is invalid.  Letters, numbers, and spaces are valid.
    VSRC_CFG_INVALID_COLOR_SCHEME_NAME = -101168,
    // You cannot overwrite the system color scheme, {0}.  Please choose another name.
    VSRC_CFG_CANNOT_OVERWRITE_SYSTEM_SCHEME = -101169,
    // Overwrite existing scheme, {0}?
    VSRC_CFG_OVERWRITE_SCHEME_CONFIRMATION = -101170,
    // The current color scheme is not considered compatible with the symbol coloring scheme.
    // 
    // Are you sure you want to switch schemes?
    VSRC_CFG_COLOR_SCHEME_INCOMPATIBLE = -101171,
    // Documentation Comment
    VSRC_CFG_DOCUMENTATION_COMMENT = -101172,
    // Documentation Keyword
    VSRC_CFG_DOCUMENTATION_KEYWORD = -101173,
    // Documentation Punctuation
    VSRC_CFG_DOCUMENTATION_PUNCTUATION = -101174,
    // Documentation Attribute
    VSRC_CFG_DOCUMENTATION_ATTRIBUTE = -101175,
    // Documentation Attribute Value
    VSRC_CFG_DOCUMENTATION_ATTR_VALUE = -101176,
    // Identifier
    VSRC_CFG_IDENTIFIER = -101177,
    // Floating Point Number
    VSRC_CFG_FLOATING_NUMBER = -101178,
    // Hexadecimal Number
    VSRC_CFG_HEX_NUMBER = -101179,
    // Single Quoted String
    VSRC_CFG_SINGLE_QUOTED_STRING = -101180,
    // Backquoted String
    VSRC_CFG_BACKQUOTED_STRING = -101181,
    // Unterminated String
    VSRC_CFG_UNTERMINATED_STRING = -101182,
    // Inactive Code
    VSRC_CFG_INACTIVE_CODE = -101183,
    // Inactive Code Keyword
    VSRC_CFG_INACTIVE_KEYWORD = -101184,
    // Modified Whitespace
    VSRC_CFG_IMAGINARY_SPACE = -101185,
    // Inactive Code Comment
    VSRC_CFG_INACTIVE_COMMENT = -101186,
    // Compiler Errors
    VSRC_CFG_ERROR = -101187,
    // References Highlight 0
    VSRC_CFG_REF_HIGHLIGHT_0 = -101188,
    // References Highlight 1
    VSRC_CFG_REF_HIGHLIGHT_1 = -101189,
    // References Highlight 2
    VSRC_CFG_REF_HIGHLIGHT_2 = -101190,
    // References Highlight 3
    VSRC_CFG_REF_HIGHLIGHT_3 = -101191,
    // References Highlight 4
    VSRC_CFG_REF_HIGHLIGHT_4 = -101192,
    // References Highlight 5
    VSRC_CFG_REF_HIGHLIGHT_5 = -101193,
    // References Highlight 6
    VSRC_CFG_REF_HIGHLIGHT_6 = -101194,
    // References Highlight 7
    VSRC_CFG_REF_HIGHLIGHT_7 = -101195,
    // Minimap Divider
    VSRC_CFG_MINIMAP_DIVIDER = -101196,
    // State file
    VSRC_CAPTION_STATE_BUILD_DATE = -101197,

    // Other
    VSRC_FF_OTHER = -101200,
    // Keyword
    VSRC_FF_KEYWORD = -101201,
    // Number
    VSRC_FF_NUMBER = -101202,
    // String
    VSRC_FF_STRING = -101203,
    // Comment
    VSRC_FF_COMMENT = -101204,
    // Preprocessing
    VSRC_FF_PREPROCESSING = -101205,
    // Line Number
    VSRC_FF_LINE_NUMBER = -101206,
    // Punctuation
    VSRC_FF_SYMBOL1 = -101207,
    // Lib Symbol
    VSRC_FF_SYMBOL2 = -101208,
    // Operator
    VSRC_FF_SYMBOL3 = -101209,
    // User Defined
    VSRC_FF_SYMBOL4 = -101210,
    // Function
    VSRC_FF_FUNCTION = -101211,
    // Attribute
    VSRC_FF_ATTRIBUTE = -101212,
    // not
    VSRC_FF_NOT = -101220,
    // Choose Directory
    VSRC_FF_CHOOSE_DIRECTORY = -101221,
    // Directory:
    VSRC_FF_CURDIR_IS = -101222,
    // {0} of {1} selected
    VSRC_FF_OF_SELECTED = -101223,
    // Sorry, cannot generate macro code for this operation.
    VSRC_FF_CANNOT_GENERATE_MACRO = -101225,
    // No files selected.
    VSRC_FF_NO_FILES_SELECTED = -101226,
    // Could not open workspace file: {0}.
    // 
    // {1}
    VSRC_FF_COULD_NOT_OPEN_WORKSPACE_FILE = -101227,
    // Invalid switch.
    VSRC_FF_INVALID_SWITCH = -101228,
    // File not found: {0}
    VSRC_FF_FILE_NOT_FOUND = -101229,
    // No files selected.
    // 
    // Read only files can't be modified.
    VSRC_FF_NO_FILES_SELECTED_READ_ONLY = -101230,
    // The following lines were skipped to prevent line truncation:
    // 
    // 
    VSRC_FF_FOLLOWING_LINES_SKIPPED = -101231,
    // Invalid font size.
    VSRC_FC_INVALID_FONT_SIZE = -101250,
    // Currently we only allow the size for the Terminal font to be selected in pixel width X pixel height form.
    VSRC_FC_TERMINAL_FONT_SIZE = -101251,
    // Invalid font name.
    VSRC_FC_INVALID_FONT_NAME = -101252,
    // Existing child edit windows are not updated.
    VSRC_FC_CHILD_WINDOWS_NOT_UPDATED = -101253,
    // You must exit and restart SlickEdit for Dialog font changes to appear.
    VSRC_FC_MUST_EXIT_AND_RESTART_DIALOG_FONT = -101254,
    // Do you wish to change the editor font in all windows?
    VSRC_FC_CHANGE_FONT_IN_ALL_WINDOWS = -101255,
    // Some of your changes will not take effect until you exit and restart SlickEdit.
    VSRC_FC_MUST_EXIT_AND_RESTART = -101256,
    // The tagging cache options will not take effect until you exit and restart SlickEdit.
    VSRC_FC_MUST_EXIT_AND_RESTART_TAGGING = -101257,
    // The thread options will not take effect until you exit and restart SlickEdit.
    VSRC_FC_MUST_EXIT_AND_RESTART_THREADS = -101258,
    // Western
    VSRC_CHARSET_WESTERN = -101275,
    // Default
    VSRC_CHARSET_DEFAULT = -101276,
    // Symbol
    VSRC_CHARSET_SYMBOL = -101277,
    // Shiftjis
    VSRC_CHARSET_SHIFTJIS = -101278,
    // Hanguel
    VSRC_CHARSET_HANGEUL = -101279,
    // GB2312
    VSRC_CHARSET_GB2312 = -101280,
    // Chinesebig5
    VSRC_CHARSET_CHINESEBIG5 = -101281,
    // OEM/DOS
    VSRC_CHARSET_OEMDOS = -101282,
    // Johab
    VSRC_CHARSET_JOHAB = -101283,
    // Hebrew
    VSRC_CHARSET_HEBREW = -101284,
    // Arabic
    VSRC_CHARSET_ARABIC = -101285,
    // Greek
    VSRC_CHARSET_GREEK = -101286,
    // Turkish
    VSRC_CHARSET_TURKISH = -101287,
    // Thai
    VSRC_CHARSET_THAI = -101288,
    // Central European
    VSRC_CHARSET_CENTRALEUROPEAN = -101289,
    // Cyrillic
    VSRC_CHARSET_CYRILLIC = -101290,
    // Mac
    VSRC_CHARSET_MAC = -101291,
    // Baltic
    VSRC_CHARSET_BALTIC = -101292,
    // Vietnamese
    VSRC_CHARSET_VIETNAMESE = -101293,
    // Once per day
    VSRC_UPCHECK_INTERVAL_1DAY = -101325,
    // Once per week
    VSRC_UPCHECK_INTERVAL_1WEEK = -101326,
    // Never
    VSRC_UPCHECK_INTERVAL_NEVER = -101327,
    // Custom
    VSRC_UPCHECK_INTERVAL_CUSTOM = -101328,
    // www.slickedit.com
    VSRC_ABOUT_WEBSITE = -101340,
    // 1 919.473.0070
    VSRC_ABOUT_SUPPORT_PHONE = -101341,
    // Serial number
    VSRC_CAPTION_SERIAL_NUMBER = -101343,
    // Licensed packages
    VSRC_CAPTION_LICENSED_PACKAGES = -101344,
    // Website
    VSRC_CAPTION_WEBSITE = -101345,
    // Technical Support Phone
    VSRC_CAPTION_SUPPORT_PHONE = -101346,
    // Technical Support Email
    VSRC_CAPTION_SUPPORT_EMAIL = -101347,
    // Expiration Date
    VSRC_CAPTION_EXPIRATION_DATE = -101348,
    // Emulation
    VSRC_CAPTION_EMULATION = -101348,
    // Installation Directory
    VSRC_CAPTION_INSTALLATION_DIRECTORY = -101349,
    // Configuration Directory
    VSRC_CAPTION_CONFIGURATION_DIRECTORY = -101350,
    // Configuration Drive Usage
    VSRC_CAPTION_CONFIGURATION_DRIVE_USAGE = -101351,
    // Spill File
    VSRC_CAPTION_SPILL_FILE = -101352,
    // Spill File Directory Drive Usage
    VSRC_CAPTION_SPILL_FILE_DIRECTORY_DRIVE_USAGE = -101353,
    // Build Date
    VSRC_CAPTION_BUILD_DATE = -101354,
    // OS
    VSRC_CAPTION_OPERATING_SYSTEM = -101355,
    // OS Version
    VSRC_CAPTION_OPERATING_SYSTEM_VERSION = -101356,
    // Version
    VSRC_CAPTION_VERSION = -101357,
    // Kernel Level
    VSRC_CAPTION_KERNEL_LEVEL = -101358,
    // Build Version
    VSRC_CAPTION_BUILD_VERSION = -101359,
    // X Server Vendor
    VSRC_CAPTION_XSERVER_VENDOR = -101360,
    // Load
    VSRC_CAPTION_MEMORY_LOAD = -101361,
    // Physical
    VSRC_CAPTION_PHYSICAL_MEMORY_USAGE = -101362,
    // Page File
    VSRC_CAPTION_PAGE_FILE_USAGE = -101363,
    // Virtual
    VSRC_CAPTION_VIRTUAL_MEMORY_USAGE = -101364,
    // Directory
    VSRC_CAPTION_DIRECTORY = -101365,
    // FLEXlm reported serial number
    VSRC_CAPTION_FLEXLM_SERIAL_NUMBER = -101366,
    // Special Characters
    VSRC_CFG_SPECIALCHARS = -101367,
    // Current Line Box
    VSRC_CFG_CURRENT_LINE_BOX = -101368,
    // Vertical Column Line
    VSRC_CFG_VERTICAL_COL_LINE = -101369,
    // Margin Column Line(s)
    VSRC_CFG_MARGINS_COL_LINE = -101370,
    // Truncation Column Line
    VSRC_CFG_TRUNCATION_COL_LINE = -101371,
    // Line Prefix Divider Line
    VSRC_CFG_PREFIX_AREA_LINE = -101372,
    // Block Matching
    VSRC_CFG_BLOCK_MATCHING = -101373,
    // Pushed Bookmark #
    VSRC_PUSHED_BOOKMARK_NAME = -101374,
    // Incremental Search Current Match
    VSRC_CFG_INC_SEARCH_CURRENT = -101375,
    // Incremental Search Highlight
    VSRC_CFG_INC_SEARCH_MATCH = -101376,
    // Hex Mode
    VSRC_CFG_HEX_MODE_COLOR = -101377,
    // Cursor Up/Down to surround lines of code. Hit Escape when done.
    VSRC_DYNAMIC_SURROUND_MESSAGE = -101378,
    // Can not move end up any further
    VSRC_DYNAMIC_SURROUND_NO_MORE_UP = -101379,
    // Can not move end down any further
    VSRC_DYNAMIC_SURROUND_NO_MORE_DOWN = -101380,
    // Licensed number of users
    VSRC_CAPTION_NOFUSERS = -101381,
    // Symbol Highlight
    VSRC_CFG_SYMBOL_HIGHLIGHT = -101382,
    // License expiration
    VSRC_CAPTION_LICENSE_EXPIRATION = -101383,
    // Licensed to
    VSRC_CAPTION_LICENSE_TO = -101384,
    // Modified file
    VSRC_CFG_MODIFIED_FILE_TAB = -101385,
    // License file
    VSRC_CAPTION_LICENSE_FILE = -101386,
    // Memory
    VSRC_CAPTION_MEMORY = -101387,
    // Modified variable
    VSRC_CFG_MODIFIED_ITEM = -101388,
    // Project Type
    VSRC_CAPTION_CURRENT_PROJECT_TYPE = -101389,
    // Language
    VSRC_CAPTION_CURRENT_LANGUAGE = -101390,
    // Screen Size
    VSRC_CAPTION_SCREEN_RESOLUTION = -101391,
    // Shell Information
    VSRC_CAPTION_SHELL_INFO = -101392,
    // Processor Architecture
    VSRC_CAPTION_PROCESSOR_ARCH = -101393,
    // License server
    VSRC_CAPTION_LICENSE_SERVER = -101394,
    // Borrow expiration
    VSRC_CAPTION_LICENSE_BORROW_EXPIRATION = -101395,
    // Encoding
    VSRC_CAPTION_CURRENT_ENCODING = -101396,
    // Selections
    VSRC_COLOR_CATEGORY_EDITOR_CURSOR = -101400,
    // General
    VSRC_COLOR_CATEGORY_EDITOR_TEXT = -101401,
    // Application colors
    VSRC_COLOR_CATEGORY_MISC = -101402,
    // Modifications
    VSRC_COLOR_CATEGORY_DIFF = -101403,
    // Highlighting
    VSRC_COLOR_CATEGORY_HIGHLIGHTS = -101404,
    // HTML and XML
    VSRC_COLOR_CATEGORY_XML = -101405,
    // Margins
    VSRC_COLOR_CATEGORY_EDITOR_COLUMNS = -101406,
    // Comments
    VSRC_COLOR_CATEGORY_COMMENTS = -101407,
    // Strings
    VSRC_COLOR_CATEGORY_STRINGS = -101408,
    // Numbers
    VSRC_COLOR_CATEGORY_NUMBERS = -101409,
    // Selection color is used for all selections in the editor windows.  Selections use the foreground color of underlying color coded text if visible against the selected background color.
    VSRC_CFG_SELECTION_DESCRIPTION = -101410,
    // This is the default color for all text which is not color coded otherwise.  Window text is the master color that other colors are allowed to inherit their background color from.
    VSRC_CFG_WINDOW_TEXT_DESCRIPTION = -101411,
    // Current Line color is used for the line under the cursor.  If the foreground color of text is visible against the Current Line background color, they are used together.  Otherwise, the Current Line foreground and background colors are used.  Current Line coloring can be enabled on per-language basis in the language “View” options.
    VSRC_CFG_CURRENT_LINE_DESCRIPTION = -101412,
    // Selected current line color is used for the current line under the cursor within a selection.  This color uses the foreground color of underlying color coded text if visible against the selected background color.
    VSRC_CFG_SELECTED_CURRENT_LINE_DESCRIPTION = -101413,
    // The message color is used for messages that appear on the SlickEdit message bar at the bottom of the window.  Typically it simply uses the system default color.
    VSRC_CFG_MESSAGE_DESCRIPTION = -101414,
    // The status color is used for text in the SlickEdit status bar at the bottom of the window.  Typically it simply uses the system default color.
    VSRC_CFG_STATUS_DESCRIPTION = -101415,
    // Cursor color is used for the character under the cursor when focus is away from the editor window or when in overstrike mode.
    VSRC_CFG_CURSOR_DESCRIPTION = -101416,
    // Modified line color is used in the left margin of editor windows for modified lines.  This color is only used if modified line coloring is enabled for the current language.  Modified line color is also used to color text in diff.
    VSRC_CFG_MODIFIED_LINE_DESCRIPTION = -101417,
    // Inserted line color is used in the left margin of editor windows for newly inserted lines.    This color is only used if modified line coloring is enabled for the current language.  Inserted line color is also used in diff to highlight lines which have been inserted.
    VSRC_CFG_INSERTED_LINE_DESCRIPTION = -101418,
    // Keyword color is used to highlight language specific keywords.
    VSRC_CFG_KEYWORD_DESCRIPTION = -101419,
    // Line number color is used for coloring line numbers in languages that require line numbers.  It should not be confused with View > Line Numbers, which displays line numbers in the editor margin.
    VSRC_CFG_LINE_NUMBER_DESCRIPTION = -101420,
    // Number color is used for language specific integer constants.
    VSRC_CFG_NUMBER_DESCRIPTION = -101421,
    // String color is used for language specific string literals.  It can also be used for here documents in certain languages and quoted attribute values in HTML/XML markup languages.
    VSRC_CFG_STRING_DESCRIPTION = -101422,
    // Block comment color is used for language specific block comments.
    VSRC_CFG_COMMENT_DESCRIPTION = -101423,
    // Preprocessor color is used for language specific preprocessor keywords.
    VSRC_CFG_PREPROCESSOR_DESCRIPTION = -101424,
    // Punctuation color us used for language specific punctuation symbols, such as braces in C/C++.
    VSRC_CFG_PUNCTUATION_DESCRIPTION = -101425,
    // Library color is used for language intrinsics and very common standard language library functions, such as strcmp() in C.
    VSRC_CFG_LIBRARY_SYMBOL_DESCRIPTION = -101426,
    // Operator color is used for language specific mathematical and logical operators.
    VSRC_CFG_OPERATOR_DESCRIPTION = -101427,
    // User defined keyword color is used for additional language specific keywords or symbols the user configures to have color coded.
    VSRC_CFG_USER_DEFINED_SYMBOL_DESCRIPTION = -101428,
    // No save (imaginary) line color is used for lines that are inserted in an editor window which will not be saved to the file.  No save lines are also used in diff.
    VSRC_CFG_NOSAVE_LINE_DESCRIPTION = -101429,
    // Function color is used to highlight identifiers which appear to be function names by virtue of being followed by a parenthesis.
    VSRC_CFG_FUNCTION_DESCRIPTION = -101430,
    // The line prefix area color is used for the right margin of the editor window.  This is the color used for line numbers when using View > Line Numbers.
    VSRC_CFG_LINE_PREFIX_AREA_DESCRIPTION = -101431,
    // The filename color is used to highlight file names in the Search Results tool window.
    VSRC_CFG_FILENAME_DESCRIPTION = -101432,
    // The highlight color is used to highlight string matches in the Search Results tool window, highlight matches using Find > Highlight all matches, and matches in the Document Overview Bar.
    VSRC_CFG_HIGHLIGHT_DESCRIPTION = -101433,
    // The attribute color is used to highlight tag attribute names in HTML and XML.
    VSRC_CFG_ATTRIBUTE_DESCRIPTION = -101434,
    // The unknown tag/element color is used to highlight tags/elements which are not defined
    VSRC_CFG_UNKNOWN_TAG_DESCRIPTION = -101435,
    // This color is used to highlight an XHTML element in an XSL style sheet.
    VSRC_CFG_XHTML_ELEMENT_IN_XSL_DESCRIPTION = -101436,
    // Special characters color is used to display special characters, such as spaces, tab characters and line endings when the view options are enabled to display those characters.
    VSRC_CFG_SPECIALCHARS_DESCRIPTION = -101437,
    // The current line box color is used when you have draw box around current line enabled.
    VSRC_CFG_CURRENT_LINE_BOX_DESCRIPTION = -101438,
    // The vertical line column color is used for drawing a vertical line at a designated marker column.  This is only drawn when the vertical line column is enabled and the editor font is a fixed width font.
    VSRC_CFG_VERTICAL_COL_LINE_DESCRIPTION = -101439,
    // The margins column line color is used to display the current wordwrap margin settings when wordwrap is enabled.  If you never want to see the margin column lines, set this color to the same as your Window Text background color.
    VSRC_CFG_MARGINS_COL_LINE_DESCRIPTION = -101440,
    // The truncation column line color is used for drawing the truncation column line when line truncation is enabled for the current language.
    VSRC_CFG_TRUNCATION_COL_LINE_DESCRIPTION = -101441,
    // The prefix area line color is the color of the vertical line which divides the left editor margin (gutter) from the editor text area.
    VSRC_CFG_PREFIX_AREA_LINE_DESCRIPTION = -101442,
    // The block matching color is used to highlight matching parentheses, braces, or begin/end keyword pairs for the item under the cursor.
    VSRC_CFG_BLOCK_MATCHING_DESCRIPTION = -101443,
    // This color is used to highlight the current incremental search match under the cursor.
    VSRC_CFG_INC_SEARCH_CURRENT_DESCRIPTION = -101444,
    // This color is used to highlight other incremental search matches in the current file.
    VSRC_CFG_INC_SEARCH_MATCH_DESCRIPTION = -101445,
    // This color is used for hex editing mode.
    VSRC_CFG_HEX_MODE_COLOR_DESCRIPTION = -101446,
    // This color is used to highlight other references to the symbol under the cursor.  This color is only used if highlight matching symbols is enabled for the current language.
    VSRC_CFG_SYMBOL_HIGHLIGHT_DESCRIPTION = -101447,
    // Line comment color is used for language specific line comments.
    VSRC_CFG_LINE_COMMENT_DESCRIPTION = -101449,
    // Documentation comment color is used for language specific documentation comments.
    VSRC_CFG_DOC_COMMENT_DESCRIPTION = -101450,
    // This color is used for keywords and tags in language specific documentation comments.
    VSRC_CFG_DOCUMENTATION_KEYWORD_DESCRIPTION = -101451,
    // This color is used for punctuation in language specific documentation comments.
    VSRC_CFG_DOCUMENTATION_PUNCTUATION_DESCRIPTION = -101452,
    // This color is used for tag attribute names in language specific documentation comments with XML or HTML markup.
    VSRC_CFG_DOCUMENTATION_ATTRIBUTE_DESCRIPTION = -101453,
    // This color is used for tag attribute values in language specific documentation comments with XML or HTML markup.
    VSRC_CFG_DOCUMENTATION_ATTR_VALUE_DESCRIPTION = -101454,
    // Floating point number color is used for language specific floating point numeric constants.
    VSRC_CFG_FLOATING_NUMBER_DESCRIPTION = -101455,
    // Hexadecimal number color is used for language specific integer and floating point numeric constants written in hexadecimal notation.
    VSRC_CFG_HEX_NUMBER_DESCRIPTION = -101456,
    // Single quoted string color is used for language specific character and string literals.
    VSRC_CFG_SINGLE_QUOTED_STRING_DESCRIPTION = -101457,
    // Backquoted string color is used for language specific string literals using backwards single quotes, such as are used in shell scripts.
    VSRC_CFG_BACKQUOTED_STRING_DESCRIPTION = -101458,
    // Unterminated string color is used at the end of a line that has a string literal which is missing its closing quote.
    VSRC_CFG_UNTERMINATED_STRING_DESCRIPTION = -101459,
    // Identifier color is used for symbols which match the language specific identifier characters.
    VSRC_CFG_IDENTIFIER_DESCRIPTION = -101460,
    // This color is used for code which is preprocessed out, such as #if 0 blocks.
    VSRC_CFG_INACTIVE_CODE_DESCRIPTION = -101461,
    // This color is used for keywords in code which is preprocessed out, such as #if 0 blocks.
    VSRC_CFG_INACTIVE_KEYWORD_DESCRIPTION = -101462,
    // Imaginary space is used in the difference editor to display whitespace which is inserted in order to balance the whitespace between the current document and the one it is being compared to.
    VSRC_CFG_IMAGINARY_SPACE_DESCRIPTION = -101463,
    // This color is used for comments in code which is preprocessed out, such as #if 0 blocks.
    VSRC_CFG_INACTIVE_COMMENT_DESCRIPTION = -101464,
    // This color is used to highlight variables or watches in the debugger windows which changed while stepping through code.
    VSRC_CFG_MODIFIED_ITEM_DESCRIPTION = -101465,
    // Navigation Hint
    VSRC_CFG_NAVHINT = -101466,
    // This color is used for navigation hints.  Navigation hints appear in the editor window and indicate the location you will be taken.
    VSRC_CFG_NAVHINT_DESCRIPTION = -101467,
    // XML/HTML Numeric Character Reference
    VSRC_CFG_XML_CHARACTER_REF = -101468,
    // This color is used for XML/HTML numeric character references &#nnnn; (decimal) or &#xhhhh; (hexadecimal).
    VSRC_CFG_XML_CHARACTER_REF_DESCRIPTION = -101469,
    // File list: loading...
    VSRC_CFG_TAG_FILES_LOADING = -101470,
    // File list: no tag file selected
    VSRC_CFG_TAG_FILES_NONE = -101471,
    // File list:  {0} files.  Tag file size: {1}
    VSRC_CFG_TAG_FILES_COUNT = -101472,
    // This color is used to mark the position of compiler errors on the vertical scrollbar.
    VSRC_CFG_ERROR_DESCRIPTION = -101473,
    // The References highlight colors are used to highlight symbol references found using Search > Go to Reference
    VSRC_CFG_REF_HIGHLIGHT_DESCRIPTION = -101474,

    // Locals
    VSRC_CODEHELP_TITLE_LOCALS = -101475,
    // Members
    VSRC_CODEHELP_TITLE_MEMBERS = -101476,
    // Imports
    VSRC_CODEHELP_TITLE_IMPORTS = -101477,
    // Static Imports
    VSRC_CODEHELP_TITLE_STATICS = -101478,
    // Current Buffer
    VSRC_CODEHELP_TITLE_BUFFER = -101479,
    // Globals
    VSRC_CODEHELP_TITLE_GLOBALS = -101480,
    // Packages
    VSRC_CODEHELP_TITLE_PACKAGES = -101481,
    // Classes
    VSRC_CODEHELP_TITLE_CLASSES = -101482,
    // Properties
    VSRC_CODEHELP_TITLE_PROPS = -101483,
    // Builtins
    VSRC_CODEHELP_TITLE_BUILTINS = -101484,
    // Parameters
    VSRC_CODEHELP_TITLE_PARAMS = -101485,
    // Controls
    VSRC_CODEHELP_TITLE_CONTROLS = -101486,
    // Keywords
    VSRC_CODEHELP_TITLE_KEYWORDS = -101487,
    // Functions
    VSRC_CODEHELP_TITLE_FUNCTIONS = -101488,
    // Procedures
    VSRC_CODEHELP_TITLE_PROCEDURES = -101489,
    // Variables
    VSRC_CODEHELP_TITLE_VARIABLES = -101490,
    // Defines
    VSRC_CODEHELP_TITLE_DEFINES = -101491,
    // Expressions
    VSRC_CODEHELP_TITLE_EXPRS = -101492,
    // Search Result Truncated
    VSRC_CFG_SEARCH_RESULT_TRUNCATED = -101493,
    // This color is used in the Search Results tool window to highlight the leading and/or trailing part of the search result line that is truncated.
    VSRC_CFG_SEARCH_RESULT_TRUNCATED_DESCRIPTION = -101494,
    // Markdown
    VSRC_COLOR_CATEGORY_MARKDOWN = -101495,
    // Markdown Header
    VSRC_CFG_MARKDOWN_HEADER = -101496,
    // Used to color Markdown headers.
    VSRC_CFG_MARKDOWN_HEADER_DESCRIPTION = -101497,
    // Markdown Code
    VSRC_CFG_MARKDOWN_CODE = -101498,
    // This color is used for Markdown code
    VSRC_CFG_MARKDOWN_CODE_DESCRIPTION = -101499,
    // Markdown Blockquote
    VSRC_CFG_MARKDOWN_BLOCKQUOTE = -101500,
    // The color used for Markdown blockquotes
    VSRC_CFG_MARKDOWN_BLOCKQUOTE_DESCRIPTION = -101501,
    // Markdown Link
    VSRC_CFG_MARKDOWN_LINK = -101502,
    // This color is used for the first part of links in Markdown.
    VSRC_CFG_MARKDOWN_LINK_DESCRIPTION = -101503,
    // Document Tab - Active
    VSRC_CFG_DOCUMENT_TAB_ACTIVE = -101504,
    // Active document tab color displays the tab for the window with focus.  Typically uses the system default colors.
    VSRC_CFG_DOCUMENT_TAB_ACTIVE_DESCRIPTION = -101505,
    // Document Tab - Modified
    VSRC_CFG_DOCUMENT_TAB_MODIFIED = -101506,
    // Modified document tab color displays the tab caption for a window that is modified. Only the foreground color is configurable since it overrides the caption color used on active, selected, and unselected tabs. To use this color, you must turn ON 'Color modified document tabs' from Options > Editing > Editor Windows.  Typically uses the system default colors.
    VSRC_CFG_DOCUMENT_TAB_MODIFIED_DESCRIPTION = -101507,
    // Document Tab - Selected
    VSRC_CFG_DOCUMENT_TAB_SELECTED = -101508,
    // Selected document tab color displays a current tab.  Note that color is overridden if tab is active or modified.  Typically uses the system default colors.
    VSRC_CFG_DOCUMENT_TAB_SELECTED_DESCRIPTION = -101509,
    // Document Tab - Unselected
    VSRC_CFG_DOCUMENT_TAB_UNSELECTED = -101510,
    // Unselected document tab color displays a non-current tab.  Note that color is overridden if tab is modified.  Typically uses the system default colors.
    VSRC_CFG_DOCUMENT_TAB_UNSELECTED_DESCRIPTION = -101511,
    // Show %s in Symbol Browser
    VSRC_SHOW_SYMBOL = -101512,
    // Show in Symbol Browser
    VSRC_SHOW_SYMBOL_NO_WORD = -101513,
    // &Find References to %s
    VSRC_FIND_REFS = -101514,
    // &Find Reference
    VSRC_FIND_REFS_NO_WORD = -101515,
    // Go to Reference for %s
    VSRC_GO_TO_REFS = -101516,
    // Go to Reference
    VSRC_GO_TO_REFS_NO_WORD = -101517,
    // &Generate Debug Statement for %s
    VSRC_GEN_DEBUG = -101518,
    // &Generate Debug Statement
    VSRC_GEN_DEBUG_NO_WORD = -101519,
    // Go to &Definition of %s
    VSRC_GO_TO_DEF = -101520,
    // Go to &Definition
    VSRC_GO_TO_DEF_NO_WORD = -101521,
    // Are you sure you want to restore the default window layout?
    VSRC_CFG_RESET_WINDOW_LAYOUT = -101522,
    // Go to Include file: %s
    VSRC_GO_TO_INCLUDE = -101523,
    // No current workspace
    VSRC_NO_CURRENT_WORKSPACE = -101524,
    // No current project
    VSRC_NO_CURRENT_PROJECT = -101525,
    // Go to Declaration of %s
    VSRC_GO_TO_DECL = -101526,
    // Go to &Declaration
    VSRC_GO_TO_DECL_NO_WORD = -101527,
    // Create cursors for each occurrence of %s
    VSRC_ADD_CURSORS_FOR_SYMBOL = -101528,
    // Prompt with choices
    VSRC_DOC_COMMENT_STYLE_PROMPT = -101529,
    // Do not convert style
    VSRC_DOC_COMMENT_STYLE_KEEP = -101530,
    // /**  Javadoc style
    VSRC_DOC_COMMENT_STYLE_JAVADOC = -101531,
    // /*!  Doxygen style
    VSRC_DOC_COMMENT_STYLE_DOXYGEN = -101532,
    // //!  Doxygen style
    VSRC_DOC_COMMENT_STYLE_DOXYGEN1 = -101533,
    // ///  Doxygen style
    VSRC_DOC_COMMENT_STYLE_DOXYGEN2 = -101534,
    // ///  XMLDOC style
    VSRC_DOC_COMMENT_STYLE_XMLDOC = -101535,
    // Migrated from
    VSRC_CAPTION_MIGRATED_CONFIG = -101536,
    // Selective Display Lines
    VSRC_CFG_SELECTIVE_DISPLAY_LINE = -101537,
    // Color for selective-display bracketing lines
    VSRC_CFG_SELECTIVE_DISPLAY_LINE_DESCRIPTION = -101538,
    // Markdown Link2
    VSRC_CFG_MARKDOWN_LINK2 = -101539,
    // This color is used for the second part of links in Markdown.
    VSRC_CFG_MARKDOWN_LINK2_DESCRIPTION = -101540,
    // Markdown Bullet
    VSRC_CFG_MARKDOWN_BULLET = -101541,
    // This color is used for markdown bullets
    VSRC_CFG_MARKDOWN_BULLET_DESCRIPTION = -101542,
    // Markdown Emphasis
    VSRC_CFG_MARKDOWN_EMPHASIS = -101543,
    // This color is used for markdown emphasis
    VSRC_CFG_MARKDOWN_EMPHASIS_DESCRIPTION = -101544,
    // Markdown Emphasis2
    VSRC_CFG_MARKDOWN_EMPHASIS2 = -101545,
    // This color is used for markdown double emphasis
    VSRC_CFG_MARKDOWN_EMPHASIS2_DESCRIPTION = -101546,
    // CSS Element
    VSRC_CFG_CSS_ELEMENT = -101547,
    // This color is used for a CSS element selector
    VSRC_CFG_CSS_ELEMENT_DESCRIPTION = -101548,
    // CSS Class
    VSRC_CFG_CSS_CLASS = -101549,
    // This color is used for a CSS class selector
    VSRC_CFG_CSS_CLASS_DESCRIPTION = -101550,
    // CSS Property
    VSRC_CFG_CSS_PROPERTY = -101551,
    // This color is used for a CSS property
    VSRC_CFG_CSS_PROPERTY_DESCRIPTION = -101552,
    // CSS Selector
    VSRC_CFG_CSS_SELECTOR = -101553,
    // This color is used for a CSS selector #id :id ::id
    VSRC_CFG_CSS_SELECTOR_DESCRIPTION = -101554,
    // Identifier2
    VSRC_CFG_IDENTIFIER2 = -101555,
    // Identifier2 color is intended to be used for another identifier color like data members.
    VSRC_CFG_IDENTIFIER2_DESCRIPTION = -101556,
    // CSS
    VSRC_COLOR_CATEGORY_CSS = -101557,
    // Tag/Element
    VSRC_CFG_TAG = -101558,
    // The tag/element color is used to highlight tags/elements which are defined
    VSRC_CFG_TAG_DESCRIPTION = -101559,
    // Unknown Attribute
    VSRC_CFG_UNKNOWN_ATTRIBUTE = -101560,
    // The unknown attribute color is used to color attributes of defined tags/elements which are not defined
    VSRC_CFG_UNKNOWN_ATTRIBUTE_DESCRIPTION = -101561,
    // Tag
    VSRC_FF_TAG = -101562,
    // The Minimap Divider color is used for the divider line between the edit window and the minimap window
    VSRC_CFG_MINIMAP_DIVIDER_DESCRIPTION=-101563,
    // Automatic detection and tagging of compiler libraries is not supported for {0}
    VSRC_AUTOTAG_NOT_SUPPORTED_FOR_FILES_OF_THIS_TYPE_ARG1=-101564,
    // Yaml
    VSRC_COLOR_CATEGORY_YAML = -101565,
    // Yaml Text Colon
    VSRC_CFG_YAML_TEXT_COLON = -101566,
    // This color is used for Yaml text folowed by colon
    VSRC_CFG_YAML_TEXT_COLON_DESCRIPTION = -101567,
    // Yaml Text
    VSRC_CFG_YAML_TEXT = -101568,
    // This color is used for YAML text
    VSRC_CFG_YAML_TEXT_DESCRIPTION = -101569,
    // Yaml Tag
    VSRC_CFG_YAML_TAG = -101570,
    // This color is used for YAML tag
    VSRC_CFG_YAML_TAG_DESCRIPTION = -101571,
    // Yaml Directive
    VSRC_CFG_YAML_DIRECTIVE = -101572,
    // This color is used for YAML directive
    VSRC_CFG_YAML_DIRECTIVE_DESCRIPTION = -101573,
    // Yaml Anchor Definition
    VSRC_CFG_YAML_ANCHOR_DEF = -101574,
    // This color is used for YAML anchor definition
    VSRC_CFG_YAML_ANCHOR_DEF_DESCRIPTION = -101575,
    // Yaml Anchor Reference
    VSRC_CFG_YAML_ANCHOR_REF = -101576,
    // This color is used for YAML anchor reference
    VSRC_CFG_YAML_ANCHOR_REF_DESCRIPTION = -101577,
    // Yaml Punctuation
    VSRC_CFG_YAML_PUNCTUATION = -101578,
    // This color is used for YAML punctuation
    VSRC_CFG_YAML_PUNCTUATION_DESCRIPTION = -101579,
    // Yaml Operator
    VSRC_CFG_YAML_OPERATOR = -101580,
    // This color is used for YAML operator
    VSRC_CFG_YAML_OPERATOR_DESCRIPTION = -101581,
    // Markdown Emphasis3
    VSRC_CFG_MARKDOWN_EMPHASIS3 = -101582,
    // This color is used for markdown single+double emphasis
    VSRC_CFG_MARKDOWN_EMPHASIS3_DESCRIPTION = -101583,
    // File specifications are a list of wildcards separated by semicolons (Example: *.cpp; *.h).
    VSRC_INCLUDE_FILE_SPECS_DESCRIPTION = -101584,
    // Exclude file specifications are a list of wildcards separated by semicolons (Example: test*.cpp; junk.cpp; build/; .svn/).
    VSRC_EXCLUDE_FILE_SPECS_DESCRIPTION = -101585,
    // Markdown Emphasis4
    VSRC_CFG_MARKDOWN_EMPHASIS4 = -101586,
    // This color is used for markdown strikeout emphasis
    VSRC_CFG_MARKDOWN_EMPHASIS4_DESCRIPTION = -101587,
};
#endif

#ifndef VSMSGDEFS_SCC_H
#define VSMSGDEFS_SCC_H
enum VSMSGDEFS_SCC {
    // VSSCC_ERROR_COULD_NOT_FIND_INSTALLED_PROVIDER_KEY_RC
    VSSCC_ERROR_COULD_NOT_FIND_INSTALLED_PROVIDER_KEY_RC = -102000,
    // VSSCC_ERROR_COULD_NOT_FIND_SPECIFIC_PROVIDER_KEY_RC
    VSSCC_ERROR_COULD_NOT_FIND_SPECIFIC_PROVIDER_KEY_RC = -102001,
    // VSSCC_ERROR_COULD_NOT_FIND_SCCSERVERPATH_RC
    VSSCC_ERROR_COULD_NOT_FIND_SCCSERVERPATH_RC = -102002,
    // VSSCC_ERROR_COULD_NOT_LOAD_LIBRARY_RC
    VSSCC_ERROR_COULD_NOT_LOAD_LIBRARY_RC = -102003,
    // VSSCC_ERROR_INIT_FAILED_RC
    VSSCC_ERROR_INIT_FAILED_RC = -102004,
    // VSSCC_ERROR_OPTION_NOT_SUPPORTED_RC
    VSSCC_ERROR_OPTION_NOT_SUPPORTED_RC = -102005,
    // The SCC provider you have configured is 32-bit and cannot be loaded by the 64-bit version of SlickEdit.  If you wish to use this system, you should use the 32-bit version of SlickEdit.
    // 
    // Some 64-bit version control systems still have 32-bit SCC provider DLLs.
    VSSCC_ERROR_MAY_BE_32_BIT_DLL_RC = -102008,
    // {0} 32-bit SCC systems are installed. These cannot be used by the 64-bit version of SlickEdit.  You may wish to try using the 32-bit version of SlickEdit.
    // 
    // Some 64-bit version control systems still have 32-bit SCC provider DLLs.
    VSSCC_WARN_ABOUT_32_BIT_SCC_SYSTEMS_RC = -102009,
    // Initialize failed
    VSSCC_E_INITIALIZEFAILED_RC = -102020,
    // Unknown project
    VSSCC_E_UNKNOWNPROJECT_RC = -102021,
    // Could not create project
    VSSCC_E_COULDNOTCREATEPROJECT_RC = -102022,
    // Not checked out
    VSSCC_E_NOTCHECKEDOUT_RC = -102023,
    // Already checked out
    VSSCC_E_ALREADYCHECKEDOUT_RC = -102024,
    // File is locked
    VSSCC_E_FILEISLOCKED_RC = -102025,
    // File checked out exclusive
    VSSCC_E_FILEOUTEXCLUSIVE_RC = -102026,
    // Access failure
    VSSCC_E_ACCESSFAILURE_RC = -102027,
    // Checkin conflict
    VSSCC_E_CHECKINCONFLICT_RC = -102028,
    // File already exists
    VSSCC_E_FILEALREADYEXISTS_RC = -102029,
    // File not controlled
    VSSCC_E_FILENOTCONTROLLED_RC = -102030,
    // File is checked out
    VSSCC_E_FILEISCHECKEDOUT_RC = -102031,
    // No specified version
    VSSCC_E_NOSPECIFIEDVERSION_RC = -102032,
    // Operation not supported
    VSSCC_E_OPNOTSUPPORTED_RC = -102033,
    // The version control system returned a non specific error code
    VSSCC_E_NONSPECIFICERROR_RC = -102034,
    // Operation not performed
    VSSCC_E_OPNOTPERFORMED_RC = -102035,
    // Type not supported
    VSSCC_E_TYPENOTSUPPORTED_RC = -102036,
    // Verify Merge
    VSSCC_E_VERIFYMERGE_RC = -102037,
    // Fix Merge
    VSSCC_E_FIXMERGE_RC = -102038,
    // Shell failure
    VSSCC_E_SHELLFAILURE_RC = -102039,
    // Invalid user
    VSSCC_E_INVALIDUSER_RC = -102040,
    // Project already open
    VSSCC_E_PROJECTALREADYOPEN_RC = -102041,
    // Project syntax error
    VSSCC_E_PROJSYNTAXERR_RC = -102042,
    // Invalid file path
    VSSCC_E_INVALIDFILEPATH_RC = -102043,
    // Project not open
    VSSCC_E_PROJNOTOPEN_RC = -102044,
    // Not authorized
    VSSCC_E_NOTAUTHORIZED_RC = -102045,
    // File syntax error
    VSSCC_E_FILESYNTAXERR_RC = -102046,
    // File does not exist
    VSSCC_E_FILENOTEXIST_RC = -102047,
};
#endif

#ifndef VSMSGDEFS_BEAUTIFIER_H
#define VSMSGDEFS_BEAUTIFIER_H
enum VSMSGDEFS_BEAUTIFIER {
    // {1} is not a valid profile name.
    VSRC_BEAUTIFIER_INVALID_PROFILE_NAME= -102300,
    // Can't open/create beautifier profile {1}.
    VSRC_BEAUTIFIER_CANT_OPEN_PROFILE= -102301,
    // Can't find beautifier profile named '{1}'  for language '{2}'.
    VSRC_BEAUTIFIER_NO_SUCH_PROFILE= -102302,
    // Null option in {1}, {2}.
    VSRC_BEAUTIFIER_NULL_OPTION= -102303,
    // Beautifier for '{1}' does not recognize the option '{2}' in profile '{3}', file {4}.
    VSRC_BEAUTIFIER_UNRECOGNIZED_OPTION= -102304,
    // Problem creating beautifier profile {1}, {2}: {3}.
    VSRC_BEAUTIFIER_PROBLEM_GENERATING_CFG= -102305,
    // Attempt to save an empty beautifier profile.
    VSRC_BEAUTIFIER_EMPTY_PROFILE= -102306,
    // Attempt to save an incomplete beautifier profile.
    VSRC_BEAUTIFIER_INCOMPLETE_PROFILE= -102307,
    // No beautifier registered for language {1}.
    VSRC_BEAUTIFIER_NOT_REGISTERED= -102308,
    // Invalid option index for beautifier: {1}.
    VSRC_BEAUTIFIER_BAD_OPTION_INDEX = -102309,
    // Option {1} is not a valid {2}. ({3})
    VSRC_BEAUTIFIER_BAD_OPTION_TYPE = -102310,
    // Beautifier expecting an editor control.
    VSRC_BEAUTIFIER_BAD_CONTROL_ID = -102311,
    // Beautifier not expecting a null file view.
    VSRC_BEAUTIFIER_NULL_FILEVIEW = -102312,
    // Can't find a user profile named {1} for language {2}
    VSRC_BEAUTIFIER_NO_SUCH_USER_PROFILE= -102313,
    // Failed trying to delete profile {1} from {2}
    VSRC_BEAUTIFIER_CANT_DELETE_PROFILE = -102314,
    // Can not create a profile with the same name as a system profile.
    VSRC_BEAUTIFIER_CANT_SHADOW_SYSTEM_PROFILE = -102315,
    // Can't find beautifier profile named '{1}'  for language '{2}' in file '{3}'.
    VSRC_BEAUTIFIER_NO_SUCH_PROFILE_IN_FILE= -102316,
    // End of beautifier errors
    VSRC_BEAUTIFIER_END_OF_ERRORS = -102500,
};
#endif

#ifndef VSMSGDEFS_OEM_H
#define VSMSGDEFS_OEM_H
enum VSMSGDEFS_OEM {
};
#endif

#ifndef CMERROR_COMMON_H
#define CMERROR_COMMON_H
enum CMERROR_COMMON {
    // End of file reached
    CMRC_EOF=-102699,
    // File '{0}' not found
    CMRC_FILE_NOT_FOUND_1ARG,
    // Path '{0}' not found
    CMRC_PATH_NOT_FOUND_1ARG,
    // Too many open files
    CMRC_TOO_MANY_OPEN_FILES,
    // Requested access to '{0}' denied
    CMRC_ACCESS_DENIED_1ARG,
    // Invalid handle
    CMRC_INVALID_HANDLE,
    // Memory control blocks destroyed.  Save files and reboot.
    CMRC_MEMORY_CONTROL_BLOCKS,
    // Insufficient memory
    CMRC_INSUFFICIENT_MEMORY,
    // Invalid drive
    CMRC_INVALID_DRIVE,
    // Current directory can not be removed
    CMRC_CURRENT_DIRECTORY_CAN_NOT_BE_REMOVED,
    // Error reading file '{0}'
    CMRC_ERROR_READING_FILE_1ARG,
    // Error writing file '{0}'
    CMRC_ERROR_WRITING_FILE_1ARG,
    // Error closing file '{0}'
    CMRC_ERROR_CLOSING_FILE_1ARG,
    // Error opening file '{0}'
    CMRC_ERROR_OPENING_FILE_1ARG,
    // No more files
    CMRC_NO_MORE_FILES,
    // findOpen not called
    CMRC_FINDOPEN_NOT_CALLED,
    // Insufficient disk space
    CMRC_INSUFFICIENT_DISK_SPACE,
    // Error seeking in file '{0}'
    CMRC_ERROR_SEEKING_IN_FILE_1ARG,
    // Media is write protected
    CMRC_MEDIA_IS_WRITE_PROTECTED,
    // Error truncating file '{0}'
    CMRC_ERROR_TRUNCATING_FILE_1ARG,
    // Invalid filename
    CMRC_INVALID_FILENAME,
    // Write to files of this type not supported
    CMRC_WRITING_TO_FILES_OF_THIS_TYPE_NOT_SUPPORTED,
    // Error creating directory '{0}'
    CMRC_ERROR_CREATING_DIRECTORY_1ARG,
    // Device not ready
    CMRC_DEVICE_NOT_READY,
    // Bad command
    CMRC_BAD_COMMAND,
    // CRC error
    CMRC_ERROR_CRC,
    // Bad length
    CMRC_BAD_LENGTH,
    // Sector not found
    CMRC_SECTOR_NOT_FOUND,
    // Out of paper
    CMRC_OUT_OF_PAPER,
    // Disk full
    CMRC_DISK_FULL,
    // Print cancelled
    CMRC_PRINT_CANCALLED,
    // I/O error
    CMRC_IO_ERROR,
    // Not a directory
    CMRC_NOT_A_DIRECTORY,
    // Buffer too small
    CMRC_BUFFER_TOO_SMALL,
    // Invalid name
    CMRC_INVALID_NAME,
    // Error changing permissions of file '{0}'
    CMRC_ERROR_CHANGING_PERMISSIONS_OF_FILE_1ARG,
    // Error changing owner of file '{0}'
    CMRC_ERROR_CHANGING_OWNER_OF_FILE_1ARG,
    // Error deleting file '{0}'
    CMRC_ERROR_DELETING_FILE_1ARG,
    // Error setting date of file '{0}'
    CMRC_ERROR_SETTING_FILE_DATE_1ARG,
    // Error opening standard file
    CMRC_ERROR_OPENING_STANDARD_FILE,

    // Invalid argument
    CMRC_INVALID_ARGUMENT,
    // Duplicate key
    CMRC_DUPLICATE_KEY,
    // Key not found
    CMRC_KEY_NOT_FOUND,
    // {0} called with invalid argument
    CMRC_INVALID_ARGUMENT_1ARG,
    // {1} call failed. Called from {0}
    CMRC_CALL_FAILED_2ARG,
    // Invalid date argument '{0}'
    CMRC_INVALID_DATE_ARGUMENT_1ARG,

    // Invalid Zip or Jar file '{0}'
    CMRC_INVALID_ZIP_OR_JAR_FILE_1ARG,
    // File listing not supported
    CMRC_FILE_LISTING_NOT_SUPPORTED,
    // File operation not supported
    CMRC_FILE_OPERATION_NOT_SUPPORTED,
    // Error decompressing Zip or Jar item '{0}'
    CMRC_ZIP_OR_JAR_DECOMPRESSION_FAILED_1ARG,
    // Error reading Zip or Jar file '{0}'
    CMRC_ERROR_READING_ZIP_OR_JAR_ITEM_1ARG,

    // Tree corrupt. Child node missing parent.
    CMRC_TREE_CORRUPT_CHILD_NODE_MISSING_PARENT,
    // No process to wait on
    CMRC_NO_PROCESS_TO_WAIT_ON,
    // Error starting process
    CMRC_ERROR_STARTING_PROCESS,
    // Error getting process exit code
    CMRC_ERROR_GETTING_EXIT_CODE,
    // No process running
    CMRC_NO_PROCESS_RUNNING,
    // Invalid find option specified
    CMRC_INVALID_FIND_OPTION_SPECIFIED,
    // EOL len1
    CMRC_EOL1,
    // EOL len2
    CMRC_EOL2,
    // EOL len0
    CMRC_EOL0,
    // Invalid permission string '{0}'
    CMRC_INVALID_PERMISSION_STRING_1ARG,
    // Error setting file permissions for '{0}'
    CMRC_ERROR_SETTING_FILE_PERMISSIONS_1ARG,
    // startIndex cannot be larger than length of string.
    CMRC_STARTINDEX_CANNOT_BE_LARGER_THAN_LENGTH,
    // Index and length must refer to a location within the string.
    CMRC_INDEX_AND_LENGTH_MUST_BE_WITHIN_STRING,
    // Index and length must refer to a location within the array.
    CMRC_INDEX_AND_LENGTH_MUST_BE_WITHIN_ARRAY,
    // Length too large
    CMRC_LENGTH_TOO_LARGE,
    // Adding after or before node not in list
    CMRC_ADDING_AFTER_OR_BEFORE_NODE_NOT_IN_LIST,
    // Remove called when list is empty
    CMRC_REMOVE_CALLED_WHEN_LIST_IS_EMPTY,
    // dequeue called when queue is empty
    CMRC_DEQUEUE_CALLED_WHEN_QUEUE_IS_EMPTY,
    // DLL {0} symbol not found
    CMRC_DLL_SYMBOL_NOT_FOUND_1ARG,
    // Timeout
    CMRC_TIMEOUT,
    // Invalid file descriptor
    CMRC_INVALID_FILE_DESCRIPTOR,
    // Network is unreachable
    CMRC_NETWORK_IS_UNREACHABLE,
    // Directory file listing not support for files of this type
    CMRC_FINDFILE_NOT_SUPPORTED_FOR_FILES_OF_THIS_TYPE,
    // Directory creates not supported for files of type '{0}'
    CMRC_MAKEDIR_NOT_SUPPORTED_FOR_FILES_OF_THIS_TYPE_ARG1,
    // Invalid port address in '{0}'
    CMRC_INVALID_PORT_ADDRESS_ARG1,
    // Error removing directory '{0}'
    CMRC_ERROR_REMOVING_DIRECTORY_1ARG,
    // Invalid option
    CMRC_INVALID_OPTION,
    // Operation cancelled
    CMRC_OPERATION_CANCELLED,
    // Attempt to obtain write lock would result in deadlock.
    CMRC_POTENTIAL_DEADLOCK_DETECTED,
    // Thread still running
    CMRC_THREAD_STILL_RUNNING,
    // {0}Infinite recursion detected while replacing '{1}'
    CMRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG,
    // String not found
    CMRC_RANGE_CHECK_CANCEL,
    // Invalid tar file '{0}'
    CMRC_INVALID_TAR_FILE_1ARG,
    // Error reading tar file '{0}'
    CMRC_ERROR_READING_TAR_ITEM_1ARG,
    // gzip program not found in PATH
    CMRC_GZIP_PROGRAM_NOT_FOUND,
    // Error reading gzip file
    CMRC_ERROR_READING_GZIP_FILE,
    // xz program not found in PATH
    CMRC_XZ_PROGRAM_NOT_FOUND,
    // Invalid cpio file '{0}'
    CMRC_INVALID_CPIO_FILE_1ARG,
    // Error reading cpio file '{0}'
    CMRC_ERROR_READING_CPIO_ITEM_1ARG,
    // bzip2 program not found in PATH
    CMRC_BZIP2_PROGRAM_NOT_FOUND,
    // Move destination '{0}' already exists
    CMRC_MOVE_DESTINATION_ALREADY_EXISTS_1ARG,
    // end
    CMRCEND_COMMON=-102700
};
#endif


#ifndef CMERROR_UNICODE_H
#define CMERROR_UNICODE_H
enum CMERROR_UNICODE {
    // Invalid code page
    CMRC_UNICODE_INVALID_CODE_PAGE=-102799,
    // Code pages with leading bytes below 128 not supported
    CMRC_UNICODE_CODE_PAGES_WITH_LEAD_BYTES_BELOW_128_NOT_SUPPORTED,
    // Code pages with undefined characters below 128 not supported
    CMRC_UNICODE_CODE_PAGES_WITH_UNDEFINED_CHARACTERS_BELOW_128_NOT_SUPPORTED,
    // Code pages with translated characters below 128 not supported
    CMRC_UNICODE_CODE_PAGES_WITH_TRANSLATED_CHARACTERS_BELOW_128_NOT_SUPPORTED,
    // Code pages with surrogates not supported
    CMRC_UNICODE_CODE_PAGES_WITH_SURROGATES_NOT_SUPPORTED,
    // Incomplete UTF-8 character
    CMRC_UNICODE_IMCOMPLETE_UTF8_CHARACTER,

    // Code page database filename not set
    CMRC_UNICODE_CODE_PAGE_FILENAME_NOT_SET,
    // Invalid code page database file
    CMRC_UNICODE_INVALID_CODEPAGE_FILE,
    // Error reading code page database file
    CMRC_UNICODE_ERROR_READING_CODEPAGE_FILE,
    // Code page not found
    CMRC_UNICODE_CODE_PAGE_NOT_FOUND,
    // Code page not loaded
    CMRC_UNICODE_CODE_PAGE_NOT_LOADED,
    // Invalid encoding
    CMRC_UNICODE_INVALID_ENCODING,
    // end
    CMRCEND_UNICODE=-102800,
};
#endif

#ifndef CMERROR_THREAD_H
#define CMERROR_THREAD_H
enum CMERROR_THREAD {
    // Failed to create semaphore
    CMRC_THREAD_FAILED_TO_CREATE_SEMAPHORE=-102899,
    // Failed to release semaphore
    CMRC_THREAD_FAILED_TO_RELEASE_SEMAPHORE,
    // Failed to release mutex
    CMRC_THREAD_RELEASE_MUTEX_FAILED,
    // Attempt to release mutex not owned by current thread
    CMRC_THREAD_ATTEMPT_TO_RELEASE_MUTEX_NOT_OWNED,
    // Monitor not owned by current thread
    CMRC_THREAD_MONITOR_NOT_OWNED_BY_CURRENT_THREAD,
    CMRCEND_THREAD=-102900,
};
#endif


#ifndef CMERROR_MINIXML_H
#define CMERROR_MINIXML_H
enum CMERROR_MINIXML {
    // Invalid comment
    CMRC_MINIXML_INVALID_COMMENT=-102999,
    // Expecting element name
    CMRC_MINIXML_EXPECTING_ELEMENT_NAME,
    // Unterminated end tag
    CMRC_MINIXML_UNTERMINATED_END_TAG,
    // Xml declaration incorrectly terminated
    CMRC_MINIXML_XML_DECLARATION_INCORRECTLY_TERMINATED,
    // Start tag incorrectly terminated
    CMRC_MINIXML_START_TAG_INCORRECTLY_TERMINATED,
    // Unexpected end of file
    CMRC_MINIXML_UNEXPECTED_END_OF_FILE,
    // Invalid binary character
    CMRC_MINIXML_INVALID_BINARY_CHARACTER,
    // Missing attribute name
    CMRC_MINIXML_MISSING_ATTRIBUTE_NAME,
    // Expecting equal sign
    CMRC_MINIXML_EXPECTING_EQUAL_SIGN,
    // Expecting quoted string
    CMRC_MINIXML_EXPECTING_QUOTED_STRING,
    // Quoted string not terminated
    CMRC_MINIXML_QUOTED_STRING_NOT_TERMINATED,
    // Unterminated processing instruction
    CMRC_MINIXML_UNTERMINATED_PROCESSING_INSTRUCTION,
    // Unterminated comment
    CMRC_MINIXML_UNTERMINATED_COMMMENT,
    // Unterminated CData section
    CMRC_MINIXML_UNTERMINATED_CDATA,
    // No root element in document type definition
    CMRC_MINIXML_NO_ROOT_ELEMENT_IN_DOCTYPE,
    // Expecting SYSTEM or PUBLIC ID in document type definition
    CMRC_MINIXML_EXPECTING_SYSTEM_OR_PUBLIC_ID,
    // Unterminated document type declaration
    CMRC_MINIXML_UNTERMINATED_DOCTYPE_DECLARATION,
    // Too many end tags
    CMRC_MINIXML_TOO_MANY_END_TAGS,
    // Mismatched end tag
    CMRC_MINIXML_MISMATCHED_END_TAG,
    // Missing end tag
    CMRC_MINIXML_MISSING_END_TAG,
    // Invalid Xml declaration
    CMRC_MINIXML_INVALID_XML_DECLARATION,
    // Xml declaration must be first
    CMRC_MINIXML_XML_DECLARATION_MUST_BE_FIRST,

    // XPath error: Invalid character expression
    CMRC_XPATH_INVALID_CHARACTER,
    // XPath error: String not terminated
    CMRC_XPATH_STRING_NOT_TERMINATED,
    // XPath error: Item could not be converted to number
    CMRC_XPATH_ITEM_COULD_NOT_BE_CONVERTED_TO_NUMBER,
    // XPath error: String '{0}' could not be converted to number
    CMRC_XPATH_STRING_COULD_NOT_BE_CONVERTED_TO_NUMBER,
    // XPath error: String '{0}' count not be converted to boolean
    CMRC_XPATH_STRING_COULD_NOT_BE_CONVERTED_TO_BOOLEAN,
    // XPath error: Converting sequence list to number not supported
    CMRC_XPATH_CONVERTING_SEQUENCE_LIST_TO_NUMBER_NOT_SUPPORTED,
    // XPath error: Converting sequence list to boolean not supported
    CMRC_XPATH_CONVERTING_SEQUENCE_LIST_TO_BOOLEAN_NOT_SUPPORTED,
    // XPath error: Converting sequence list to string not supported
    CMRC_XPATH_CONVERTING_SEQUENCE_LIST_TO_STRING_NOT_SUPPORTED,
    // XPath error: List with more than one item specified.  Expecting string argument.
    CMRC_XPATH_LIST_WITH_MORE_THAN_ONE_ITEM_CAN_NOT_BE_CONVERTED_TO_STRING,
    // XPath error: Boolean argument specified. Expecting string argument
    CMRC_XPATH_BOOLEAN_ARGUMENT_SPECIFIED_EXPECTING_STRING_ARGUMENT,
    // XPath error: Integer argument specified. Expecting string argument
    CMRC_XPATH_INTEGER_ARGUMENT_SPECIFIED_EXPECTING_STRING_ARGUMENT,
    // XPath error: XPath expression must be compiled before evaluation
    CMRC_XPATH_EXPRESSION_MUST_BE_COMPILED_BEFORE_EVALUATION,
    // XPath error: Expression does not evaluate to a single node
    CMRC_XPATH_EXPRESSION_DOES_NOT_EVALUATE_TO_A_SINGLE_NODE,
    // XPath error: Expression too complex
    CMRC_XPATH_EXPRESSION_TOO_COMPLEX,
    // XPath error: Expecting close bracket
    CMRC_XPATH_EXPECTING_CLOSE_BRACKET,
    // XPath error: Searching for a local name within a namespace not supported
    CMRC_XPATH_SEARCHING_FOR_A_LOCAL_NAME_WITHIN_A_NAMESPACE_NOT_SUPPORTED,
    // XPath error: Invalid axis name '{0}'
    CMRC_XPATH_INVALID_AXIS_NAME_1ARG,
    // XPath error: Unknown or unsupported function '{0}'
    CMRC_INVALID_UNKNOWN_FUNCTION_1ARG,
    // XPath error: Expecting processing instruction name
    CMRC_XPATH_EXPECTING_PROCESSING_INSTRUCTION_NAME,
    // XPath error: Expecting close parenthesis
    CMRC_XPATH_EXPECTING_CLOSE_PAREN,
    // XPath error: Predicate expression not yet supported after parenthesized expression
    CMRC_XPATH_PREDICATE_EXPRESSIONS_NOT_YET_SUPPORTED_AFTER_PAREN,
    // XPath error: Binary operator not yet supported
    CMRC_XPATH_BINARY_OPERATOR_NOT_YET_SUPPORTED,
    // XPath error: Expecting node test
    CMRC_XPATH_EXPECTING_NODE_TEST,
    // XPath error: Invalid or unsupported expression
    CMRC_XPATH_INVALID_OR_UNSUPPORTED_EXPRESSION,
    // XPath error: Unary - only supported for a constant integer
    CMRC_XPATH_UNARY_MINUS_ONLY_SUPPORTED_FOR_CONSTANT_INTEGER,
    // XPath error: Not enough arguments specified in function call
    CMRC_XPATH_NOT_ENOUGH_ARGUMENTS,
    // XPath error: Too many arguments specified in function call
    CMRC_XPATH_TOO_MANY_ARGUMENTS,
    // XPath error: Error parsing function arguments
    CMRC_XPATH_ERROR_PARSING_FUNCTION_ARGUMENTS,
    // XPath error: Expression does not evaluate to a sequence
    CMRC_XPATH_EXPRESSION_DOES_NOT_EVALUATE_TO_A_SEQUENCE,
    // XPath error: Extra characters at end of expression
    CMRC_XPATH_EXTRA_CHARACTERS,
    CMRCEND_MINIXML=-103000,
};
#endif

#ifndef CMERROR_REGEX_H
#define CMERROR_REGEX_H
enum CMERROR_REGEX {
    // Invalid UTF-8 character in regular expression
    CMRC_REGEX_INVALID_UTF8_CHARACTER_IN_REGULAR_EXPRESSION=-103099,
    // Expecting open brace
    CMRC_REGEX_EXPECTING_OPEN_BRACE,
    // Expecting close brace
    CMRC_REGEX_EXPECTING_CLOSE_BRACE,
    // Unknown unicode character name '{0}'
    CMRC_REGEX_UNKNOWN_UNICODE_CHARACTER_NAME_1ARG,
    // Unknown unicode character name
    CMRC_REGEX_UNKNOWN_UNICODE_CHARACTER_NAME,
    // Must surround backreference name with '<>', single quotes, or '{}'
    CMRC_REGEX_MUST_SURROUND_BACKREFENCE_NAME_WITH,
    // Tagged expression name not terminated
    CMRC_REGEX_BACKREFENCE_NAME_NOT_TERMINATED,
    // Tagged expression name '{0}' not found
    CMRC_REGEX_BACKREFENCE_NAME_NOT_FOUND_1ARG,
    // Expecting close parenthesis
    CMRC_REGEX_EXPECTING_CLOSE_PAREN,
    // Invalid control escape character '\c?'
    CMRC_REGEX_INVALID_CONTROL_ESCAPE_CHARACER,
    // Invalid hexadecimal escape character
    CMRC_REGEX_INVALID_HEX_ESCAPE_CHARACTER,
    // Invalid decimal escape character '\o#{...}'
    CMRC_REGEX_INVALID_DECIMAL_ESCAPE_CHARACTER,
    // Unrecognized escape '{0}'
    CMRC_REGEX_UNRECOGNIZED_ESCAPE_1ARG,
    // Character set not terminated
    CMRC_REGEX_CHARACTER_SET_NOT_TERMINATED,
    // Character set subtraction of intersection must be last
    CMRC_REGEX_CHARACTER_SET_SUBTRACTION_OR_INTERSECTION_MUST_BE_LAST,
    // Unicode escape character (\xhhhh) must be 4 hexadecimal digits
    CMRC_REGEX_UNICODE_ESCAPE_CHARACTER_MUST_BE_4_HEX_DIGITS,
    // Quantifier follows nothing
    CMRC_REGEX_QUANTIFIER_FOLLOWS_NOTHING,
    // Invalid colon (':') category
    CMRC_REGEX_INVALID_COLON_CATEGORY,
    // Invalid quantifier
    CMRC_REGEX_INVALID_QUANTIFIER,
    // Invalid regular expression
    CMRC_REGEX_INVALID_REGULAR_EXPRESSION,
    // Invalid backreference name
    CMRC_REGEX_INVALID_BACKREFERENCE_NAME,
    // Break key pressed.  Regular expression search cancelled"
    CMRC_REGEX_BREAK_KEY_PRESSED,
    // Regular expression recursion too deep
    CMRC_REGEX_RECURSION_TOO_DEEP,
    // Invalid word regular expression specified
    CMRC_REGEX_INVALID_WORD_RE,
    // Expecting close brace for '\p{...}' property name
    CMRC_REGEX_EXPECTING_CLOSE_BRACE_FOR_PROPERTY_NAME,
    // Expecting ':]' to close '[:...:]' posix name
    CMRC_REGEX_EXPECTING_CLOSE_BRACKET_TO_CLOSE_POSIX_NAME,
    // Can't find property '{0}'
    CMRC_REGEX_CANT_FIND_PROPERTY_1ARG,
    // Expecting close brace for hex escape character '\x{...}'
    CMRC_REGEX_EXPECTING_CLOSE_BRACE_FOR_HEX_ESCAPE_CHARACTER,
    // Expecting close brace for decimal escape character '\o#{...}'
    CMRC_REGEX_EXPECTING_CLOSE_BRACE_FOR_DECIMAL_ESCAPE_CHARACTER,
    // Invalid tagged expression name '{0}'. Must be a valid index or begin with a letter followed by a-z0-9_
    CMRC_REGEX_INVALID_TAGGED_EXPRESSION_NAME_1ARG,
    // Expecting close brace for '\N{...}' unicode character name
    CMRC_REGEX_EXPECTING_CLOSE_BRACE_FOR_UNICODE_CHARACTER_NAME,
    // Expecting open brace for '\N{...}' unicode character name specification
    CMRC_REGEX_EXPECTING_OPEN_BRACE_FOR_UNICODE_CHARACTER_NAME_SPEC,
    // Invalid octal escape character
    CMRC_REGEX_INVALID_OCTAL_ESCAPE_CHARACTER,
    // Invalid condition in '?(condition)YesPattern|NoPattern'
    CMRC_REGEX_INVALID_CONDITION_IN_YES_NO_PATTERN,
    // Expecting character set or escape in extended character set
    CMRC_REGEX_EXPECTING_CHARACTER_SET_OR_ESCAPE_IN_EXTENDED_CHARACTER_SET,
    // Incomplete expression within '(?[ ])'
    CMRC_REGEX_INCOMPLETE_EXPRESSION_WITHIN_EXTENDED_CHARACTER_SET,
    // Must specify 2 hex digits (\xhh) in extended character set
    CMRC_REGEX_MUST_SPECIFY_2_HEX_DIGITS_IN_EXTENDED_CHARACTER_SET,
    // Infinite recursion
    CMRC_REGEX_INFINITE_RECURSION,
    // Recursion not supported for look behind expressions
    CMRC_REGEX_SUBROUTINE_CALLS_NOT_SUPPORTED_FOR_LOOK_BEHIND_EXPRESSIONS,
    // Expecting numeric tagged expression
    CMRC_REGEX_EXPECTING_NUMERIC_TAGGED_EXPRESSION,
    // Tagged expression called and defined multiple times
    CMRC_REGEX_TAGGED_EXPRESSION_CALLED_AND_DEFINED_MULTIPLE_TIMES,
    // Tagged expression called and defined in look behind expression
    CMRC_REGEX_TAGGED_EXPRESSION_CALLED_AND_DEFINED_IN_LOOK_BEHIND_EXPRESSION,
    // Expecting valid \@?? operator
    CMRC_REGEX_EXPECTING_VALID_BACKSLASH_ATSIGN_OPERATOR,
    //  \@?? operator must follow an atom (not operator or parenthesis)
    CMRC_REGEX_BACKSLASH_ATSIGN_MUST_FOLLOW_AN_ATOM,
    // Expecting valid @?? operator
    CMRC_REGEX_EXPECTING_VALID_ATSIGN_OPERATOR,
    //  @?? operator must follow an atom (not operator or parenthesis)
    CMRC_REGEX_ATSIGN_MUST_FOLLOW_AN_ATOM,
    // Invalid or unsupported \%?? syntax
    CMRC_REGEX_INVALID_OR_UNSUPPORTED_BACKSLASH_PERCENT,
    // Invalid \_?? syntax
    CMRC_REGEX_INVALID_BACKSLASH_PERCENT_SYNTAX,
    // Invalid or unsupported \z?? syntax
    CMRC_REGEX_INVALID_OR_UNSUPPORTED_BACKSLASH_Z_SYNTAX,
    CMRCEND_REGEX=-103100
};
#endif


#ifndef CMERROR_GREP_H
#define CMERROR_GREP_H
enum CMERROR_GREP {
    // cmgrep [options] [pattern] {[-t|-l] [filename] {-wc wildcard} {-x wildcard}}
    //     -pc             Only print count of matches and first match location.
    //     -p1             Find first/one match location and print filename,line, column. 
    //     -po             Print byte offset instead of line number and column.
    //     -p=[flcton1s]   Print specified-filename,line,col,text,offset,count,one,stats.
    //     -t              Recurse directories.
    //     -z              Treat zip files as directories of files.
    //     -- pattern      Search for pattern which starts with a '-'.
    //     -f PatternFile  Read pattern from file specified.
    //     -fb PatternFile Same as -f option except all bytes count.
    //     -h or -?        Display this help.
    //     -l ListFile     Search files listed in ListFile.  Use -t in list file
    //                     to recurse.  filenames may be double quoted.
    //     -m              Do not print match location. Same as -p=t
    // 
    //     -i              Case insensitive search (ignore case).
    //     -r or -u        SlickEdit or Perl regular expression search.
    //     -w              Match whole word. Default word chars [a-zA-Z0-9_$].
    //     -w=[...]        Match whole word and sets word chars.
    //     -w:p            Match word prefix.
    //     -w:ps           Strict match word prefix (word char must match).
    //     -w:s            Match word suffix.
    //     -w:ss           Strict match word suffix (word char must precede match).
    //     -y              Binary search.  Always case sensitive.
    //     --encoding E    Specify encoding for all files. Default is AutoUnicode2
    //     --max-line-size n Maximum line length output size (default 3000)
    //     --truncate-cols n Maximum bytes displayed before and after match (default 1000)
    //     --threads n     Use n threads
    //     --color=[always|never|auto]  Turns color output on/off.
    //     --max-color n   Specifies maximum number of lines to be colored in the 
    //                     SlickEdit process buffer. -1 for maximum.
    //     -A n            Show n lines after match
    //     -B n            Show n lines before match
    //     -C n            Show n lines before and after match
    //     -wc wildcard    ant-like wild card to match. Use double quotes to match
    //                     spaces in wildcard. When specified, filename must be a 
    //                     directory. Can specify more than one wildcard if 
    //                     subsequent wildcards don't start with -.
    // 
    //                     Examples
    //                        -wc *.cpp *.h     -- Match .cpp and .h files
    //                        -wc -file.cpp     -- file starts with '-' must be first
    //                        -wc dir1/p*/**/backup/*.txt
    //                        cmgrep main -t -wc dir1/p*/**/backup/*.txt
    //                                
    //     -x wildcard     ant-like wild card to exclude. Use double quotes to match
    //                     spaces in wildcard. When specified, filename must be a 
    //                     directory. Can specify more than one wildcard if 
    //                     subsequent wildcards don't start with -.
    // 
    //                     Examples
    //                        -x **/*.bak junk*.cpp
    //                        -x **/dir/**     -- Exclude directory
    //                        -x **/dir/       -- Exclude directory
    //                        -x dir/          -- Exclude directory (need -t)
    //                        cmgrep main -t -wc "*.cpp" -x "junk*.cpp" backup/
    //                        cmgrep main -t junk.cpp -x -file1.cpp -x -file2.cpp
    //
    CMRC_GREP_HELP=-103199,
    CMRCEND_GREP=-103200,
};
#endif


#ifndef CMERROR_MISC_H
#define CMERROR_MISC_H
enum CMERROR_MISC {
    // Invalid cmtar file '{0}'.  File must start with cmtar<tab>.
    CMRC_CMTAR_INVALID_CMTAR_TAB_NOT_FOUND_1ARG=-103299,
    // Invalid file header at seek position {0} of cmtar file '{1}'.  Filename has 0 length.
    CMRC_CMTAR_INVALID_FILE_HEADER_INVALID_FILENAME_2ARG,
    // Invalid directory header at seek position {0} of cmtar file '{1}'.  Invalid permissions '{2}'
    CMRC_CMTAR_INVALID_DIR_HEADER_3ARG,
    // Invalid file header at seek position {0} of cmtar file '{1}'.  Hex file size '{2}' invalid.
    CMRC_CMTAR_INVALID_FILE_HEADER_HEX_FILE_SIZE_INVALID_3ARG,
    // Invalid file header at seek position {0} of cmtar file '{1}'.  UTC file time '{2}' invalid.
    CMRC_CMTAR_INVALID_FILE_HEADER_UTC_FILE_TIME_INVALID_3ARG,
    // Invalid license key
    CMRC_INVALID_LICENSE_KEY,
    // String is not a valid floating point number
    CMRC_STRING_IS_NOT_A_VALID_FLOATING_POINT_NUMBER,
    // Exponent too large
    CMRC_EXPONENT_TOO_LARGE,
    //Power does not support numbers with an exponent
    CMRC_POWER_DOES_NOT_SUPPORT_NUMBERS_WITH_AN_EXPONENT, 
    // Divide by zero
    CMRC_DIVIDE_BY_ZERO,
    // String is not a valid decimal number
    CMRC_STRING_IS_NOT_A_VALID_DECIMAL_NUMBER, 
    // Number too large
    CMRC_NUMBER_TOO_LARGE,
    // Error reading response or response invalid
    CMRC_ERROR_READING_RESPONSE,
    // URL status condition - {0}
    CMRC_URL_STATUS_1ARG,
    // URL moved
    CMRC_URL_MOVED,
    // URL response not supported - {0}
    CMRC_URL_RESPONSE_NOT_SUPPORTED_1ARG,
    // URL redirect to HTTPS protocol not supported
    CMRC_URL_MOVED_HTTPS_NOT_SUPPORTED,
    CMRCEND_MISC=-103300,
};
#endif


#ifndef CMERROR_SOCKET_H
#define CMERROR_SOCKET_H
enum CMERROR_SOCKET {
    // Could not find suitable winsock DLL
    CMRC_SOCKET_COULD_NOT_FIND_SUITABLE_WINSOCK_DLL=-103399,
    // WSAStartup must be call before using this function
    CMRC_SOCKET_WSASTARTUP_MUST_BE_CALLED,
    // The specified address family is not supported.
    CMRC_SOCKET_ADDRESS_FAMILER_NOT_SUPPORTED,
    // A blocking Windows Sockets 1.1 call is in progress, or the service provider is still processing a callback function
    CMRC_SOCKET_BLOCK_WINDOWS_1_1_CALL_IS_IN_PROGRESS,
    // No more socket descriptors are available
    CMRC_SOCKET_NO_MORE_SOCKET_DESCRIPTORS_ARE_AVAILABLE,
    // No buffer space is available. The socket cannot be created
    CMRC_SOCKET_NO_BUFFER_SPACE_AVAILABLE,
    // The specified protocol is not supported
    CMRC_SOCKET_PROTOCOL_NOT_SUPPORTED,
    // The specified protocol is the wrong type for this socket
    CMRC_SOCKET_INVALID_PROTOCOL_TYPE_FOR_SOCKET,
    // The specified socket type is not supported in this address family
    CMRC_SOCKET_INVALID_SOCKET_TYPE_FOR_ADDRESS_FAMILY,
    // The socket address already in use and the socket has not been marked to allow address reuse
    CMRC_SOCKET_ADDRESS_ALREADY_IN_USE,
    // Address not available
    CMRC_SOCKET_ADDRESS_NOT_AVAILABLE,
    // The socket is already bound to an address or invalid value for ai_flags or level is not valid, or the information in optval is not valid
    CMRC_SOCKET_ALREADY_BOUND_TO_AN_ADDRESS,
    // Invalid socket descriptor or socket already closed
    CMRC_SOCKET_INVALID_SOCKET_DESCRIPTOR,
    // Socket is already connected
    CMRC_SOCKET_ALREADY_CONNECTED,
    // Socket is not of the type that supports the listen operation
    CMRC_SOCKET_LISTENING_NOT_SUPPORTED,

    // Temporary failure in name resolution
    CMRC_SOCKET_TEMPORARY_FAILURE_IN_NAME_RESOLUTION,
    // Nonrecoverable failure in name resolution.
    CMRC_SOCKET_NONRECOVERABLE_FAILURE_IN_NAME_RESOLUTION,
    // No address is associated with the host name specified
    CMRC_SOCKET_NO_ADDRESS_ASSOCIATED_WITH_HOST_NAME,
    // Host name or service not found
    CMRC_SOCKET_HOST_NOT_FOUND,
    // The servname parameter is not supported for the ai_socktype specified
    CMRC_SOCKET_TYPE_NOT_FOUND,
    // Call to closeSocket() failed
    CMRC_SOCKET_CLOSE_SOCKET_FAILED,
    // The (blocking) Windows Socket 1.1 call was canceled through WSACancelBlockingCall
    CMRC_SOCKET_ALREADY_CANCELLED,
    // The socket is marked as nonblocking and SO_LINGER is set to a non-zero time-out value
    CMRC_SOCKET_WOULD_BLOCK,
    // Socket must be opened for listening for connections
    CMRC_SOCKET_MUST_BE_IN_LISTENING_STATE,
    // Port number of service name is not valid
    CMRC_SOCKET_INVALID_PORT_OR_SERVICE,
    // Connection has timed out
    CMRC_SOCKET_CONNECTION_HAS_TIMED_OUT,
    // The option is unknown or unsupported for the specified provider or socket (see SO_GROUP_PRIORITY limitations)
    CMRC_SOCKET_THE_OPTION_IS_UNKNOWN_OR_UNSUPPORTED,
    // Connection has been reset when SO_KEEPALIVE is set.
    CMRC_SOCKET_NOT_CONNECTED,
    // Socket argument fault
    CMRC_SOCKET_FAULT,
    // Socket connect failed
    CMRC_SOCKET_CONNECTION_FAILED,
    // Socket connection closed
    CMRC_SOCKET_CONNECTION_CLOSED,
    // Connection aborted
    CMRC_SOCKET_CONNECTION_ABORTED,
    // Connection reset
    CMRC_SOCKET_CONNECTION_RESET,
    // Socket shut down
    CMRC_SOCKET_SHUTDOWN,
    // Connection refused
    CMRC_SOCKET_CONNECTION_REFUSED,
    // Network down
    CMRC_SOCKET_NETWORK_DOWN,
    // No protocol available
    CMRC_SOCKET_NO_PROTOCOL_AVAILABLE,
    // Shutdown failed
    CMRC_SOCKET_SHUTDOWN_FAILED,
    // No more data
    CMRC_SOCKET_NO_MORE_DATA,
    // Socket call to getnameinfo failed
    CMRC_SOCKET_CALL_TO_GETNAMEINFO_FAILED,
    // Socket call to getsockname failed
    CMRC_SOCKET_CALL_TO_GETSOCKNAME_FAILED,
    // Socket call to getpeername failed
    CMRC_SOCKET_CALL_TO_GETPEERNAME_FAILED,
    // Socket call to getsockopt failed
    CMRC_SOCKET_CALL_TO_GETSOCKOPT_FAILED,
    // Socket call to setsockopt failed
    CMRC_SOCKET_CALL_TO_SETSOCKOPT_FAILED,
    // Call to socket() failed
    CMRC_SOCKET_CALL_TO_SOCKET_FAILED,
    // Socket call to bind() failed
    CMRC_SOCKET_CALL_TO_BIND_FAILED,
    // Socket call to listen() failed
    CMRC_SOCKET_CALL_TO_LISTEN_FAILED,
    // Socket call to getaddrinfo failed
    CMRC_SOCKET_CALL_TO_GETADDRINFO_FAILED,
    // Socket call to send() failed
    CMRC_SOCKET_CALL_TO_SEND_FAILED,
    // Socket call to recv() failed
    CMRC_SOCKET_CALL_TO_RECV_FAILED,
    CMRCEND_SOCKET= -103400,
};
#endif


#ifndef CMERROR_TLEXER_H
#define CMERROR_TLEXER_H
enum CMERROR_TLEXER {
    // Expecting processing instruction name
    CMRC_TLEXER_EXPECTING_PROCESSING_INSTRUCTION_NAME=-103499,
    // Expecting '&lt;[CDATA['
    CMRC_TLEXER_EXPECTING_CDATA_BRACKET,
    // Expecting a markup declaration
    CMRC_TLEXER_EXPECTING_A_MARKUP_DECLARATION,
    // Expecting '&lt;!--' or '&lt;![CDATA'
    CMRC_TLEXER_EXPECTING_LTMINUSMINUS_LTEXBRACKET_CDATA_BRACKET,
    // Expecting element name
    CMRC_TLEXER_EXPECTING_ELEMENT_NAME,
    // Expecting entity name
    CMRC_TLEXER_EXPECTING_ENTITY_NAME,
    // Expecting attribute name
    CMRC_TLEXER_EXPECTING_ATTRIBUTE_NAME,
    // Expecting attribute value
    CMRC_TLEXER_EXPECTING_ATTRIBUTE_VALUE,
    // Entity reference must be terminated with ';'
    CMRC_TLEXER_ENTITY_REFERENCE_MUST_BE_TERMINATED_WITH_SEMICOLON,
    // Entity reference must be followed by entity name
    CMRC_TLEXER_ENTITY_REFERENCE_MUST_BE_FOLLOWED_BY_ENTITY_NAME,
    // Entity not found
    CMRC_TLEXER_ENTITY_NOT_FOUND,
    // String not terminated
    CMRC_TLEXER_STRING_NOT_TERMINATED,
    // Comment not terminated
    CMRC_TLEXER_COMMENT_NOT_TERMINATED,
    // Element not terminated
    CMRC_TLEXER_ELEMENT_NOT_TERMINATED,
    // Tag '{0}' must be defined
    CMRC_TLEXER_UNKNOWN_TAG_MUST_BE_DEFINED,
    // File '{0}' already included
    CMRC_TLEXER_FILE_ALREADY_INCLUDED_1ARG,
    // Comment delimiter expected
    CMRC_TLEXER_COMMENT_DELIMITER_EXPECTED,
    // First character of regex token '{0}' must evaluate to character set
    CMRC_TLEXER_REGEX_KEYWORD_MUST_EVALUATE_TO_CHARACTER_SET_1ARG,
    // Invalid suffix on numeric constant
    CMRC_TLEXER_INVALID_SUFFIX_ON_NUMBERIC_CONSTANT,
    CMRCEND_TLEXER=-103500,
};
#endif


#ifndef CMERROR_PLUGIN_H
#define CMERROR_PLUGIN_H
enum CMERROR_PLUGIN {
    // Plugin '{0}' has circular dependencies
    CMRC_PLUGIN_HAS_CIRCULAR_DEPENDENCIES_1ARG=-103599,
    // Plugin '{0}' depends on '{1}' which does not exist
    CMRC_PLUGIN_DEPENDS_ON_MISSING_PLUGIN_2ARG,
    // Plugin '{0}' requires different version of plugin '{1}'
    CMRC_PLUGIN_REQUIRES_PLUGIN_WITH_DIFFERENT_VERSION_2ARG,
    // {0} {1}: Invalid merge style
    CMRC_PLUGIN_CONFIG_ERROR_INVALID_MERGE_STYLE_2ARG,
    // {0} {1}: Invalid boolean value
    CMRC_PLUGIN_CONFIG_ERROR_INVALID_BOOLEAN_VALUE_2ARG,
    // Invalid setting '{0}' for property '{1}'
    CMRC_XMLCFG_INVALID_SETTING_FOR_PROPERTY_2ARG,
    // Unknown property '{0}'
    CMRC_XMLCFG_UNKNOWN_PROPERTY_1ARG,
    // Property '{0}' does not support the apply attribute
    CMRC_XMLCFG_PROPERTY_DOES_NOT_SUPPORT_THE_APPLY_ATTRIBUTEY_1ARG,
    // Property '{0}' has invalid value '{1}'
    CMRC_PLUGIN_PROPERTY_HAS_INVALID_VALUE_2ARG,
    // Unknown Property type
    CMRC_XMLCFG_UNKNOWN_PROPERTY_TYPE,
    // Profile not found
    CMRC_PLUGIN_PROFILE_NOT_FOUND,
    CMRCEND_PLUGIN=-103600,
};
#endif


#ifndef CMERROR_FTP_H
#define CMERROR_FTP_H
enum CMERROR_FTP {
    // Failed to connect to host {0}. {1}
    CMRC_FTP_FAILED_TO_CONNECT_2ARG=-103699,
    // Failed to connect to host {0} IP Address {1}. {2}
    CMRC_FTP_FAILED_TO_CONNECT_3ARG,
    // FTP command '{0}' failed. {1}
    CMRC_FTP_COMMAND_FAILED_2ARG,
    // FTP command 'PASS ****' failed. {0}
    CMRC_FTP_PASS_COMMAND_FAILED_1ARG,
    // FTP data port accept connection failed
    CMRC_FTP_DATAPORT_ACCEPT_CONNECTION_FAILED,
    // Unable to open FTP data port
    CMRC_FTP_UNABLE_TO_OPEN_A_DATA_PORT,
    // Command aborted
    CMRC_FTP_COMMAND_ABORTED,
    CMRCEND_FTP=-103700,
};
#endif
/********EXTRA BELOW************************/
#ifndef CMERROR_DB_H
#define CMERROR_DB_H
enum CMERROR_DB {
    // Record not found
    CMRC_DB_RECORD_NOT_FOUND=-103799,
    //Feature not supported
    CMRC_DB_FEATURE_NOT_SUPPORTED,
    //No more duplicates
    CMRC_DB_NO_MORE_DUPLICATES,
    //Removed last duplicate                                                            
    CMRC_DB_REMOVED_LAST_DUPLICATE,
    //Invalid record location
    CMRC_DB_INVALID_RECORD_LOCATION,
    //Missing required field
    CMRC_DB_MISSING_REQUIRED_FIELD,
    //Cache block index out of range
    CMRC_DB_CACHE_BLOCK_INDEX_OUT_OF_RANGE,
    //Record too large for block
    CMRC_DB_RECORD_TOO_LARGE_FOR_BLOCK,
    //Database '{0}' corrupt. Signature not valid
    CMRC_DB_INVALID_SIGNATURE_1ARG,
    //Database '{0}' corrupt or may not have been closed properly
    CMRC_DB_DATABASE_CORRUPT_1ARG,
    //Database '{0}' corrupt. Invalid file size
    CMRC_DB_DATABASE_CORRUPT_FILESIZE_INCORRECT_1ARG,
    //Too many index fields
    CMRC_DB_TOO_MANY_INDEX_FIELDS,
    //Field not found
    CMRC_DB_FIELD_NOT_FOUND,
    //Table too complex
    CMRC_DB_TABLE_TOO_COMPLEX,
    //Field already defined
    CMRC_DB_FIELD_ALREADY_DEFINED,
    //All string fields must be defined first
    CMRC_DB_ALL_STRING_FIELDS_MUST_BE_DEFINED_FIRST,
    //Database '{0}' must be recreated for this machine architecture
    CMRC_DB_DATABASE_HAS_INCORRECT_MACHINE_ARCHITECTURE_1ARG,
    //Can't recreate database '{0}' while database is still open
    CMRC_DB_SYMBOL_DATABASE_IS_STILL_OPEN_1ARG,
    //Opening or creating databases not allowed during close all operation
    CMRC_DB_OPENING_OR_CREATING_NOT_ALLOW_DURING_CLOSE_ALL_OPERATION,
    //LoadAndClose only supported for read only in memory databases
    CMRC_DB_LOADANDCLOSE_ONLY_SUPPORTED_FOR_READ_ONLY_IN_MEMORY_DATABASES,
    //Free large called with invalid capacity size
    CMRC_DB_FREE_LARGE_CALLED_WITH_INVALID_CAPACITY_SIZE,
    //Free large called with invalid seek position
    CMRC_DB_FREE_LARGE_CALLED_WITH_INVALID_SEEK_POSITION,
    //Can't close symbol database from thread which doesn't have the database open
    CMRC_DB_CANT_CLOSE_SYMBOL_DATABASE_FROM_CURRENT_THREAD,
    CMRCEND_DB=-103800,
};
#endif
#ifndef CMERROR_TAGSDB_H
#define CMERROR_TAGSDB_H
enum CMERROR_TAGSDB {
    //Invalid database. Database marker missing.
    CMRC_TAGSDB_INVALID_DATABASE_TAGSDB_DATABASE_MARKER_MISSING=-103899,
    //Version not supported
    CMRC_TAGSDB_VERSION_NOT_SUPPORTED,
    //Table or index missing
    CMRC_TAGSDB_TABLE_OR_INDEX_MISSING,
    CMRCEND_TAGSDB=-103900,
};
#endif
#ifndef CMERROR_LICENSE_H
#define CMERROR_LICENSE_H
enum CMERROR_LICENSE {
    //License must have encrypt element
    CMRC_LICENSE_MUST_HAVE_ENCRYPT_ELEMENT=-103999,
    //Issued date attribute is not valid
    CMRC_LICENSE_ISSUED_DATE_ATTRIBUTE_IS_NOT_VALID,
    //Start date attribute is not valid
    CMRC_LICENSE_START_DATE_ATTRIBUTE_IS_NOT_VALID,
    // M="Expires date attribute is not valid
    CMRC_LICENSE_EXPIRES_DATE_ATTRIBUTE_IS_NOT_VALID,
    //License must have ProductInfo element
    CMRC_LICENSE_MUST_HAVE_PRODUCT_INFO_ELEMENT,
    //Product version attribute is not valid
    CMRC_LICENSE_PRODUCT_VERSION_ATTRIBUTE_IS_NOT_VALID,
    //Invalid license file
    CMRC_LICENSE_INVALID_LICENSE_FILE,
    //License expired
    CMRC_LICENSE_EXPIRED,
    //License not valid for configuration
    CMRC_LICENSE_NOT_VALID_FOR_CONFIGURATION,
    //License is for an older version
    CMRC_LICENSE_IS_FOR_AN_OLDER_VERSION,
    //License is not valid for this product
    CMRC_LICENSE_NOT_VALID_FOR_THIS_PRODUCT,
    //License is not valid before the start date
    CMRC_LICENSE_NOT_VALID_BEFORE_START_DATE,
    //License must have non blank vendor id
    CMRC_LICENSE_MUST_HAVE_NON_BLANK_VENDOR_ID,
    //License must have non blank product id
    CMRC_LICENSE_MUST_HAVE_NON_BLANK_PRODUCT_ID,
    //Borrowed license failure: {0}
    CMRC_LICENSE_BORROWED_LICENSE_FAILURE_1ARG,
    //Borrow requires product be checked out first
    CMRC_LICENSE_BORROW_REQUIRES_PRODUCT_BE_CHECKED_OUT,
    //Return requires product be checked out first
    CMRC_LICENSE_RETURN_REQUIRES_PRODUCT_BE_CHECKED_OUT,
    //Product already checked out
    CMRC_LICENSE_PRODUCT_ALREADY_CHECKED_OUT,
    //Product not checked out
    CMRC_LICENSE_PRODUCT_NOT_CHECKED_OUT,
    //Host id not valid for configuration
    CMRC_LICENSE_HOSTID_NOT_VALID_FOR_CONFIGURATION,
    //Disk serial number not valid for configuration
    CMRC_LICENSE_DISK_SERIAL_NUMBER_NOT_VALID_FOR_CONFIGURATION,
    //Host name not valid for configuration
    CMRC_LICENSE_HOST_NAME_NOT_VALID_FOR_CONFIGURATION,
    //User name not valid for configuration
    CMRC_LICENSE_USER_NAME_NOT_VALID_FOR_CONFIGURATION,
    //License missing Sign element
    CMRC_LICENSE_MISSING_SIGN_ELEMENT,
    //License missing Encrypt element
    CMRC_LICENSE_MISSING_ENCRYPT_ELEMENT,
    //Invalid result received from server
    CMRC_LICENSE_INVALID_RESULT,
    //Invalid characters in vendor id
    CMRC_LICENSE_INVALID_CHARACTERS_IN_VENDOR_ID,
    //Invalid characters in product id
    CMRC_LICENSE_INVALID_CHARACTERS_IN_PRODUCT_ID,
    //usage:
    //
    //cmlicutil [-s 27101@server] command
    //cmlicutil [-s 27101@server1,20715@server2] command
    //cmlicutil borrow -status       -- Displays user borrow file
    //cmlicutil borrow -return       -- Returns all borrowed products
    //cmlicutil borrow vendorid productid ver yyyy-mm-dd [hh:mm] -- borrow product
    //cmlicutil down                 -- Shuts down server
    //cmlicutil hostid               -- Displays client machine information
    //cmlicutil remove checkoutId1 checkoutId2 ... -- Forces removal of checkout or borrow
    //cmlicutil reread               -- Server re-reads   license files
    //cmlicutil stat                 -- Displays license usage
    //cmlicutil stat -a              -- Displays license and user usage
    //cmlicutil stat -v              -- Displays debug license information
    //cmlicutil version              -- Display server version
    CMRC_LICENSE_LICUTIL_HELP,
    //Failed to create hash
    CMRC_LICENSE_HASH_FAILED,
    CMRCEND_LICENSE=-104000,
};
#endif


#ifndef CMERROR_BEAUTIFIER_H
#define CMERROR_BEAUTIFIER_H
enum CMERROR_BEAUTIFIER {
    //{0} {1}: Unexpected preprocessor token
    CMRC_UNEXPECTED_PROPROCESS_TOKEN_2ARG=-104099,
    //{0} {1}: Unexpected '{2}' token
    CMRC_UNEXPECTED_TOKEN_3ARG,
    //{0} {1}: Unexpected close brace, possible missing ';'
    CMRC_UNEXPECTED_CLOSE_BRACE_POSSIBLE_MISSING_SEMICOLON_2ARG,
    //Category Name='{0}' missing Id attribute
    CMRC_CATEGORY_MISSING_ID_1ARG,
    //Tag '{0}' has circular parent hierarchy
    CMRC_TAG_HAS_CIRCULAR_PARENT_TAG_HIEARCHY_1ARG,
    //Parent tag '{0}' specified in tag {1} not found
    CMRC_PARENT_TAG_SPECIFIED_IN_TAG_NOT_FOUND_2ARG,
    //{0} {1}: Unexpected close brace
    CMRC_UNEXPECTED_CLOSE_BRACE_2ARG,
    //{0} {1}: End does not match current block
    CMRC_END_DOES_NOT_MATCH_CURRENT_BLOCK_2ARG,
    //Tag element missing 'n' attribute
    CMRC_TAG_ELEMENT_MISSING_N_ATTRIBUTE,
    //Failed to create beautifier '{0}'
    CMRC_BEAUTIFIER_FAILED_TO_CREATE_BEAUTIFIER_1ARG,
    //No beautifier for file '{0}'
    CMRC_BEAUTIFIER_NO_BEAUTIFIER_FOR_FILE_1ARG,
    //Profile '{0}' not found for '{1}'
    CMRC_BEAUTIFIER_PROFILE_NOT_FOUND_2ARG,
    CMRCEND_BEAUTIFIER=-104100,
};
#endif

#ifndef CMERROR_PARSER_H
#define CMERROR_PARSER_H
enum CMERROR_PARSER {
    //No parser for file '{0}'
    CMRC_PARSER_NO_PARSER_FOR_FILE_1ARG=-104199,
    //Failed to create parser '{0}'
    CMRC_PARSER_FAILED_TO_CREATE_PARSER_1ARG,
    CMRCEND_PARSER=-104200,
};
#endif

#ifndef CMERROR_CSV_H
#define CMERROR_CSV_H
enum CMERROR_CSV {
    //Double quoted string not terminated
    CMRC_CSV_DQSTRING_NOT_TERMINATED=-104299,
    //Extra characters outside of double quotes
    CMRC_CSV_EXTRA_CHARACTERS_OUTSIDE_OF_DOSTRING,
    //{0} {1}: column parse error: {2}
    CMRC_CSV_COL_PARSE_ERROR_3ARG,
    //Column parse error
    CMRC_CSV_COL_PARSE_ERROR,
    //{0} {1}: Not enough columns
    CMRC_CSV_NOT_ENOUGH_COLS_2ARG,
    //Not enough columns
    CMRC_CSV_NOT_ENOUGH_COLS,
    //{0} {1}: Too many columns
    CMRC_CSV_TOO_MANY_COLS_2ARG,
    //Too many columns
    CMRC_CSV_TOO_MANY_COLS,
    //Column '{0}' not found
    CMRC_CSV_COL_NOT_FOUND_1ARG,
    //Column not found
    CMRC_CSV_COL_NOT_FOUND,
    // Invalid CSV handle
    CMRC_CSV_INVALID_HANDLE,
    // Invalid CSV row handle
    CMRC_CSV_INVALID_ROW_HANDLE,
    CMRCEND_CSV=-104300,
};
#endif

#ifndef VSMSGDEFS_SVC_H
#define VSMSGDEFS_SVC_H
enum VSMSGDEFS_SVC {
    // Could not get version control interface for {0}
    VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC = -104399,
    // Interface for {0} not available
    VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC,
    // Could not get version control file interface for {0}
    VSRC_SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC,
    // Interface for {0} not available
    VSRC_SVC_FILE_INTERFACE_NOT_AVAILABLE_RC,
    // File {0} not found
    VSRC_SVC_FILE_NOT_FOUND_RC,
    // File {0} not found
    VSRC_SVC_SYSTEM_NOT_SUPPORTED_RC,
    // Annotations for file {0} not found
    VSRC_SVC_ANNOTATIONS_NOT_AVAILABLE_RC,
    // Could not get history for file '{0}'
    //
    // {1}
    VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,
    // Could not get current version for file '{0}'
    //
    // {1}
    VSRC_SVC_COULD_NOT_GET_CURRENT_VERSION_FILE,
    // Could not get current local version for file '{0}'
    //
    // {1}
    VSRC_SVC_COULD_NOT_GET_CURRENT_LOCAL_VERSION_FILE,
    //
    VSRC_SVC_CURRENT_VERSION_IS_MOST_RECENT,
    // Could not get status for file '{0}'.
    VSRC_SVC_COULD_NOT_GET_FILE_STATUS,
    // Could not {0} file '{1}'.
    //
    // {2}
    VSRC_SVC_COULD_NOT_UPDATE_FILE,
    // Could not {0} file '{1}'.
    //
    // {2}
    VSRC_SVC_COULD_NOT_REVERT_FILE,
    // Could not {0} file '{1}'.
    //
    // {2}
    VSRC_SVC_COULD_NOT_EDIT_FILE,
    // Could not submit change list for '{0}'
    //
    // {1}
    VSRC_SVC_CHANGELIST_FAILED,
    // Could not {0} '{1}'
    //
    // {2}
    VSRC_SVC_COMMIT_FAILED,
    // Could not find version control executable '{0}'
    VSRC_SVC_COULD_NOT_FIND_VC_EXE,
    // Command '{0}' not available
    VSRC_SVC_COMMAND_NOT_AVAILABLE,
    // Could not get out of date files for '{0}'
    //
    // {1}
    VSRC_SVC_COULD_NOT_GET_OUT_OF_DATE_FILES,
    // Could not get locally modified files for '{0}'
    //
    // {1}
    VSRC_SVC_COULD_NOT_GET_LOCALLY_MODIFIED_FILES,
    // Could not get information for '{0}'
    VSRC_SVC_COULD_NOT_GET_INFO,
    // Could not compare '{0}' with most up to date version
    //
    // {1}
    VSRC_SVC_COULD_NOT_COMPARE_FILE,
    // Could not {0} file '{1}'
    //
    // {2}
    VSRC_SVC_COULD_NOT_ADD_FILE,
    // Could not {0} file '{1}'
    //
    // {2}
    VSRC_SVC_COULD_NOT_DELETE_FILE,
    // Could not {0} file '{1}'
    //
    // {2}
    VSRC_SVC_COULD_NOT_RESOLVE_FILE,
    // Could not list URL '{0}'
    VSRC_SVC_COULD_NOT_LIST_URL,
    // Could not push to repository
    //
    // {0}
    VSRC_SVC_COULD_NOT_PUSH_TO_REPOSITORY,
    // Could not pull from repository
    //
    // {0}
    VSRC_SVC_COULD_NOT_PULL_FROM_REPOSITORY,
    // Could not get remote file for local file {0}
    VSRC_SVC_COULD_NOT_GET_REMOTE_FILE,
    // Could not get remote repository information for any of the following paths: {0}
    VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION,
    VSRC_SVC_END_ERRORS = -104400
};
#endif


