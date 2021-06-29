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
#pragma option(metadata,"debug.e")

///////////////////////////////////////////////////////////////////////////
// Constants and flags
///////////////////////////////////////////////////////////////////////////

// event handling flags
const VSDEBUG_EVENT_SUSPEND_ALL=         0x0001;
const VSDEBUG_EVENT_SUSPEND_THREAD=      0x0002;
const VSDEBUG_EVENT_GOTOPC=              0x0004;
const VSDEBUG_EVENT_STOP=                0x0008;
const VSDEBUG_EVENT_UPDATE_CLASSES=      0x0010;

// thread flags
const VSDEBUG_THREAD_FLAG_ZOMBIE=        0x0001;
const VSDEBUG_THREAD_FLAG_RUNNING=       0x0002;
const VSDEBUG_THREAD_FLAG_SLEEPING=      0x0004;
const VSDEBUG_THREAD_FLAG_MONITOR=       0x0008;
const VSDEBUG_THREAD_FLAG_WAIT=          0x0010;
const VSDEBUG_THREAD_FLAG_SUSPENDED=     0x0020;
const VSDEBUG_THREAD_FLAG_FROZEN=        0x0040;

// class, field, and method modifier flags
const VSDEBUG_FLAG_PUBLIC=           0x00000001;
const VSDEBUG_FLAG_PACKAGE=          0x00000002;
const VSDEBUG_FLAG_PROTECTED=        0x00000004;
const VSDEBUG_FLAG_PRIVATE=          0x00000008;
const VSDEBUG_FLAG_FINAL=            0x00000010;
const VSDEBUG_FLAG_SUPER=            0x00000020;
const VSDEBUG_FLAG_INTERFACE=        0x00000040;
const VSDEBUG_FLAG_ABSTRACT=         0x00000080;
const VSDEBUG_FLAG_STATIC=           0x00000100;
const VSDEBUG_FLAG_TRANSIENT=        0x00000200;
const VSDEBUG_FLAG_SYNCHRONIZED=     0x00000400;
const VSDEBUG_FLAG_VOLATILE=         0x00000800;
const VSDEBUG_FLAG_NATIVE=           0x00001000;
const VSDEBUG_FLAG_VERIFIED=         0x00002000;
const VSDEBUG_FLAG_PREPARED=         0x00004000;
const VSDEBUG_FLAG_INITIALIZED=      0x00008000;
const VSDEBUG_FLAG_ERROR=            0x00010000;
const VSDEBUG_FLAG_SYNTHETIC=        0x00020000;
const VSDEBUG_FLAG_ARRAY=            0x00040000;

// constants for items expanded under classes
const VSDEBUG_CLASS_FIELDS=          0x00000001;
const VSDEBUG_CLASS_METHODS=         0x01000000;

// constants for exceptions stop condition
const VSDEBUG_EXCEPTION_STOP_WHEN_THROWN=    0x1;
const VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT=    0x2;
const VSDEBUG_EXCEPTION_STOP_WHEN_UNCAUGHT=  0x4;

// indices of the tabs on the debugger properties dialog
const VSDEBUG_PROPS_INFORMATION_TAB=     0;
const VSDEBUG_PROPS_SETTINGS_TAB=        1;
const VSDEBUG_PROPS_NUMBERS_TAB=         2;
const VSDEBUG_PROPS_FILTERS_TAB=         3;
const VSDEBUG_PROPS_DIRECTORIES_TAB=     4;
const VSDEBUG_PROPS_CONFIGURATIONS_TAB=  5;

// breakpoint types
const VSDEBUG_BREAKPOINT_LINE=           0;
const VSDEBUG_BREAKPOINT_METHOD=         1;
const VSDEBUG_BREAKPOINT_ADDRESS=        2;
const VSDEBUG_WATCHPOINT_READ=           3;
const VSDEBUG_WATCHPOINT_WRITE=          4;
const VSDEBUG_WATCHPOINT_ANY=            5;

// breakpoint flags
const VSDEBUG_WATCHPOINT_INSTANCE=       0x01;
const VSDEBUG_WATCHPOINT_STOP_ACTIVATE=  0x02;


///////////////////////////////////////////////////////////////////////////
// Typedef and constants needed for handling user defined views
///////////////////////////////////////////////////////////////////////////

// Update all views
const VSDEBUG_UPDATE_ALL=             1;

// Debugger initialization and finalization
const VSDEBUG_UPDATE_INITIALIZE=      2;
const VSDEBUG_UPDATE_FINALIZE=        3;

// Debugger version information
const VSDEBUG_UPDATE_VERSION=         4;

// Threads and stack frames
// use dbg_get_cur_thread() and dbg_get_cur_frame()
const VSDEBUG_UPDATE_THREADS=         5;
const VSDEBUG_UPDATE_CUR_THREAD=      6;
const VSDEBUG_UPDATE_STACK=           7;
const VSDEBUG_UPDATE_CUR_FRAME=       8;
const VSDEBUG_UPDATE_SUSPENDED=       9;

// Variables of different types
const VSDEBUG_UPDATE_VARIABLES=      10;
const VSDEBUG_UPDATE_LOCALS=         11;
const VSDEBUG_UPDATE_MEMBERS=        12;
const VSDEBUG_UPDATE_AUTOVARS=       13;
const VSDEBUG_UPDATE_WATCHES=        14;

// classes, registers, memory
const VSDEBUG_UPDATE_CLASSES=        15;
const VSDEBUG_UPDATE_REGISTERS=      16;
const VSDEBUG_UPDATE_MEMORY=         17;

// breakpoints and exceptions
const VSDEBUG_UPDATE_BREAKPOINTS=    18;
const VSDEBUG_UPDATE_EXCEPTIONS=     19;

// enabled-ness of buttons
const VSDEBUG_UPDATE_BUTTONS=        20;

// anything else
const VSDEBUG_UPDATE_MISCELLANEOUS=  21;

// disassembly
const VSDEBUG_UPDATE_DISASSEMBLY=    22;

// start of user-defined callback reasons
const VSDEBUG_UPDATE_USER=           100;

// Constants for bases number values can be displayed in
const VSDEBUG_BASE_DEFAULT=     0;
const VSDEBUG_BASE_BINARY=      2;
const VSDEBUG_BASE_OCTAL=       8;
const VSDEBUG_BASE_DECIMAL=     10;
const VSDEBUG_BASE_HEXADECIMAL= 16;
const VSDEBUG_BASE_CHAR=       256;
const VSDEBUG_BASE_DEFAULT_FLOAT=   0x1000;
const VSDEBUG_BASE_FLOATING_POINT=  0x2000;
const VSDEBUG_BASE_SCIENTIFIC=      0x4000;
const VSDEBUG_BASE_PLAIN_TEXT=     0x10000;
const VSDEBUG_BASE_UNICODE_TEXT=   0x20000;

const VSDEBUG_BASE_NUMBER_MASK=  0x0fff;
const VSDEBUG_BASE_FLOAT_MASK=   0xf000;
const VSDEBUG_BASE_STRING_MASK=  0xf0000;

const VSDEBUG_LOG=              'debug';

///////////////////////////////////////////////////////////////////////////
// Slick-C def-vars for Debugger configuration
///////////////////////////////////////////////////////////////////////////

/**
 * The number of lines to scan surrounding the current line
 * of code for variables to show in the debugger's 
 * auto variable tool window.
 * 
 * @default 3
 * @categories Configuration_Variables
 */
int def_debug_auto_lines/*=3*/;
/**
 * The default type of watchpoint to set.
 * <ul>
 * <li><b>VSDEBUG_WATCHPOINT_READ </b> -- stop on read access
 * <li><b>VSDEBUG_WATCHPOINT_WRITE</b> -- stop on write access
 * <li><b>VSDEBUG_WATCHPOINT_ANY  </b> -- stop on any access (read or write)
 * </ul>
 * 
 * @default VSDEBUG_WATCHPOINT_WRITE
 * @categories Configuration_Variables
 */
int def_debug_watchpoint_type/*=VSDEBUG_WATCHPOINT_WRITE*/;
/**
 * Amount of time to wait before debugger should time out on commands (in seconds).
 * 
 * @default 30 seconds
 * @categories Configuration_Variables
 */
int def_debug_timeout/*=30*/;
/**
 * Max amount of time in milliseconds to spend in _UpdateDebugger(), 
 * handling events. This also controls the frequency that _UpdateDebugger()
 * triggers when the application being debugged is suspended.
 * 
 * @default 1000
 * @categories Configuration_Variables
 */
int def_debug_max_update_time/*=1000*/;
/**
 * Minimum amount of time in milliseconds to spend in 
 * _UpdateDebugger(), waiting for events.
 * This also controls the frequency that _UpdateDebugger() 
 * triggers when the application being debugged is running.
 * 
 * @default 250
 * @categories Configuration_Variables
 */
int def_debug_min_update_time/*=250*/;
/**
 * Amount of time to wait before updating debug windows (in milliseconds)
 * 
 * @default 100 milliseconds
 * @categories Configuration_Variables
 */
int def_debug_timer_delay/*=100*/;
/**
 * Amount of time to for java debugger to display
 * "loading classes" message (in seconds).
 * 
 * @default 5 seconds
 * @categories Configuration_Variables
 */
int def_debug_message_duration/*=5*/;
/**
 * Default port to use to connect to vsdebugio application when
 * debugging using GDB or LLDB on Unix.
 * 
 * @default 8001
 * @categories Configuration_Variables
 */
_str def_debug_vsdebugio_port/*="8001"*/;
/**
 * Debugging support options flags
 * Bitset of VSDEBUG_OPTION_*
 * <ul>
 * <li><b>VSDEBUG_OPTION_SUPPORT_HOTSWAP   </b> -- support hot swap (Java)
 * <li><b>VSDEBUG_OPTION_CONFIRM_DIRECTORY </b> -- confirm directory when locating source files
 * <li><b>VSDEBUG_OPTION_ALLOW_EDITING     </b> -- allow source files to be edited during debugging
 * <li><b>VSDEBUG_OPTION_MOUSE_OVER_INFO   </b> -- show values of variables when mouse floats over them
 * <li><b>VSDEBUG_OPTION_AUTO_CORRECT_BP   </b> -- automatically correct breakpoint locations
 * </ul>
 * 
 * @default 0xffffffff
 * @categories Configuration_Variables
 */
int def_debug_options/*=0xffffffff*/;
/**
 * Debugging logging support.  If enabled, all transactions between
 * SlickEdit and the host debugger (Java or GDB) will be logged to
 * the log file (vs.log in the logs subdir of the user 
 * configuration directory). 
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_debug_logging/*=0*/;

struct DebugNumberFormat {
   int base;   // Base to display values in
};
/**
 * Debugger number formats.
 * Hash table of integer types mapped to the 
 * numerical base to format them using.
 * 
 * @default null
 * @categories Configuration_Variables
 */
DebugNumberFormat def_debug_number_formats:[];

/**
 * Debugger array or string value maximum length to expand.
 * 
 * @default 1000
 * @categories Configuration_Variables
 */
int def_debug_max_elements/*=1000*/;

/**
 * Extension list of files that can be attached to by the debugger
 * 
 * @default EXE_FILE_RE (.exe on Windows, "" on Unix) 
 * @categories Configuration_Variables
 */
_str def_debug_exe_extensions/*=EXE_FILE_RE*/;

/**
 * (Windows only). Set to true to use gdb remote proxy application
 * to mediate connection between gdb and remote target. This setting only
 * applies to attaching to remote target.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_gdb_use_proxy/*=true*/;

/**
 * (Windows only). Port to use when gdb connects to a remote target through
 * the gdb remote proxy application. def_gdb_use_proxy must be set to true
 * for this to have any effect. Set to "" to use the default port number of
 * 8002.
 * 
 * @default "" 
 * @categories Configuration_Variables
 */
_str def_gdb_proxy_port/*=""*/;

///////////////////////////////////////////////////////////////////////////
// Slick-C entry points
///////////////////////////////////////////////////////////////////////////

/**
 * Display the version of the vsdebug.dll
 * 
 * @categories Debugger_Functions
 */
_command int vsdebug_version();
/**
 * Initialize the debugger library and prepare to connect to
 * one or more debugging sessions.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
_command int dbg_initialize();
/**
 * Close all existing debugging sessions, and free all memory
 * and files associated with the debugging session.
 * 
 * @categories Debugger_Functions
 */
_command void dbg_finalize();




////////////////////////////////////////////////////////////////////////
// GENERAL SESSION MANAGEMENT
////////////////////////////////////////////////////////////////////////

/**
 * Create a new debugger session object handle.
 * If successful, the new session will be made the active session.
 * 
 * @param package_name  name of debugger integration package
 *                      (gdb, jdwp, dotnot, ...)
 * @param session_name  name of debugger session
 * @param copy_setup    copy existing setup data for this session name?
 * 
 * @return session ID of the new debugger session
 * 
 * @example
 * To create a GDB debugger session
 * <pre>
 *    int session_id = dbg_create_new_session("gdb", "myUnixApp");
 *    if (session_id < 0) {
 *       printf("could not create session object\n");
 *    } else {
 *       printf("new session ID = %d\n",session_id);
 *    }  
 * </pre>
 * 
 * @see dbg_get_num_sessions
 * @see dbg_destroy_session
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_create_new_session(_str package_name, _str session_name, bool copy_setup);

/**
 * @return Return the number of debugger sessions active.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_get_num_sessions();

/**
 * @return Return the session ID of the active debugger session.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_get_current_session();

/**
 * Designate a new session to be the active debugger session.
 * 
 * @return the previous active session ID, 0 if none, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_set_current_session(int new_session_id);

/**
 * Get all of the session ID's for the active sessions
 *
 * @param id_array      array of integers
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_get_all_sessions(int (&id_array)[]);

/**
 * Return the session ID of the first session with the specified name
 * 
 * @param session_name      debugger session name
 * 
 * @return session ID (1 .. max_session) pointer, &lt;0 on failure
 * 
 * @example
 * To find a debugging session named "MySession"
 * <pre>
 *    int session_id = dbg_find_session("MySession");
 *    if (session_id < 0) {
 *       printf("session not found\n");
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_find_session(_str session_name);

/**
 * Return the debugger system callback name for the given session ID
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return "" on failure, otherwise return session callback name
 *
 * @see dbg_find_session
 * @see dbg_get_session_name
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern _str dbg_get_callback_name(int session_id);

/**
 * Return the session name for the given session ID
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return NULL on failure, otherwise return session name
 *
 * @see dbg_find_session
 * @see dbg_set_session_name
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern _str dbg_get_session_name(int session_id);

/**
 * Modify the session name for the given session ID
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param session_name  new name for session
 * 
 * @return 0 on success, &lt;0 on failure
 *
 * @see dbg_find_session
 * @see dbg_get_session_name
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_set_session_name(int session_id, _str session_name);

/**
 * Return true if the given session is active.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return true (1) if the session is active, 0 otherwise.
 *
 * @see dbg_find_session
 * @see dbg_get_session_name
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_is_session_active(int session_id);

/**
 * Destroy the given session and remove it from the session list.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @example
 * To destroy the first debugger session.
 * <pre>
 *    dbg_destroy_session(1);
 * </pre>
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @see dbg_create_new_session
 * @see dbg_get_num_sessions
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_destroy_session(int session_id);


////////////////////////////////////////////////////////////////////////
// SESSION CAPABILITIES
////////////////////////////////////////////////////////////////////////

/**
 * Convert the named debugger capability to an int in the
 * capability enumeration type.
 * 
 * @param capability    name of capability to look up
 *        <ul>
 *        <li><b>initialize             </b> -- initialize debugger connection
 *        <li><b>finalize               </b> -- clean up debugger connection
 *        <li><b>terminate              </b> -- stop debugging
 *        <li><b>detach                 </b> -- detach from debugging session
 *        <li><b>restart                </b> -- restart from start of program
 *        <li><b>do_command             </b> -- perform debugger command
 *        <li><b>error_message          </b> -- get last error message
 *        <li><b>print_output           </b> -- print output to vsdebugio
 *        <li><b>print_info             </b> -- send info to vsdebugio
 *        <li><b>print_error            </b> -- send error message to vsdebugio
 *        <li><b>send_direct_input      </b> -- send input to direct to debugee
 *        <li><b>version                </b> -- get version of debugger
 *        <li><b>test_version           </b> -- test version of debugger
 *        <li><b>reload                 </b> -- reload module and continue
 *        <li><b>get_paths              </b> -- get debugger paths
 *        <li><b>resolve_path           </b> -- resolve source file path
 *        <li><b>suspend                </b> -- suspend execution
 *        <li><b>resume                 </b> -- resume execution
 *        <li><b>interrupt              </b> -- send interrupt to thread
 *        <li><b>step_into              </b> -- step into function
 *        <li><b>step_over              </b> -- step over statement
 *        <li><b>step_out               </b> -- step out of function
 *        <li><b>step_into_runtimes     </b> -- step into runtime function
 *        <li><b>step_instr             </b> -- step by instruction
 *        <li><b>set_instruction_pointer</b> -- move instruction pointer
 *        <li><b>disable_breakpoint     </b> -- disable breakpoint
 *        <li><b>enable_breakpoint      </b> -- enable breakpoint
 *        <li><b>probe_breakpoint       </b> -- test breakpoint
 *        <li><b>disable_watchpoint     </b> -- disable watchpoint
 *        <li><b>enable_watchpoint      </b> -- enable watchpoint
 *        <li><b>disable_exception      </b> -- disable exception
 *        <li><b>enable_exception       </b> -- enable exception
 *        <li><b>handle_event           </b> -- poll for asynchronous event
 *        <li><b>update_threads         </b> -- update thread list
 *        <li><b>update_thread_groups   </b> -- update thread group tree
 *        <li><b>update_thread_names    </b> -- update thread names
 *        <li><b>update_thread_states   </b> -- update thread states
 *        <li><b>update_stack           </b> -- update stack
 *        <li><b>update_locals          </b> -- update local variables
 *        <li><b>expand_local           </b> -- expand local variable
 *        <li><b>modify_local           </b> -- modify local variable
 *        <li><b>update_members         </b> -- update class members variables
 *        <li><b>expand_member          </b> -- expand class member variable
 *        <li><b>modify_member          </b> -- modify class member variable
 *        <li><b>update_watches         </b> -- update user defined watches
 *        <li><b>expand_watch           </b> -- expand watch variable
 *        <li><b>modify_watch           </b> -- modify watch variable
 *        <li><b>update_auto_watches    </b> -- update auto watch variables
 *        <li><b>expand_auto_watch      </b> -- expand auto watch variable
 *        <li><b>modify_auto_watch      </b> -- modify auto watch variable
 *        <li><b>eval_condition         </b> -- evaluate condition
 *        <li><b>eval_expression        </b> -- evaluate expression
 *        <li><b>update_classes         </b> -- update classes
 *        <li><b>expand_class           </b> -- expand class members
 *        <li><b>expand_methods         </b> -- expand class methods
 *        <li><b>expand_fields          </b> -- expand class fields
 *        <li><b>expand_nested          </b> -- expand inner classes
 *        <li><b>expand_parents         </b> -- expand class parents
 *        <li><b>modify_field           </b> -- modify static class field
 *        <li><b>update_registers       </b> -- update registers
 *        <li><b>update_memory          </b> -- update memory contents
 *        <li><b>modify_memory          </b> -- modify memory contents
 *        </ul>
 * 
 * @return DEBUG_CAPABILITY_NOT_FOUND if no such capability exists,
 *         otherwise, it returns the debugger capability index.
 * 
 * @example
 * To look up the capability ID for initialize
 * <pre>
 *    int cap = dbg_translate_capability("initialize");
 *    return cap;
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_translate_capability(_str capability);

/**
 * @return the string representation of the given debugger capability
 * 
 * @param capability    capability type (DEBUG_CAPABILITY_*)
 * 
 * @example
 * To look up the call back name expected for update registers
 * <pre>
 *    _str cap = dbg_get_capability_name(DEBUG_CAPABILITY_UPDATE_REGISTERS);
 *    _message_box("registers = " :+ cap);
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern _str dbg_get_capability_name(int capability);

/**
 * Check if the given debugger session implements the given capability.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param capability    debugger capability (DEBUG_CAPABILITY_*)
 * 
 * @return &gt;0 if the feature is implemented, 0 if not, &lt;0 on error.
 * 
 * @see dbg_session_is_name_implemented
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_is_implemented(int session_id, int capability);

/**
 * Check if the given debugger session implements the given capability.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param capability    debugger capability
 * 
 * @return 1 if the feature is implemented, 0 if not, &lt;0 on error.
 * 
 * @see dbg_session_is_implemented
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_is_name_implemented(int session_id, _str capability);



////////////////////////////////////////////////////////////////////////
// GENERAL DEBUGGER INITIALIZATION AND SHUTDOWN
////////////////////////////////////////////////////////////////////////

/**
 * Initialize the connection to the debugger
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param host_or_program  The usage of this argument may vary between
 *                         debuggers and types of connections.
 *                         For example:
 *                         <ul>
 *                         <li><i>host</i> -- Name of host to connect to.
 *                             If the host name is the empty string,
 *                             assume 'localhost'
 *                         <li><i>program</i> -- Program to debug.
 *                             If we are attaching to a port this
 *                             parameter is still useful becuase it is
 *                             needed for loading debugging information
 *                         </ul>
 * 
 * @param port_or_pid      The usage of this argument may vary between
 *                         debuggers and types of connections.
 *                         For example:
 *                         <ul>
 *                         <li><i>port</i> -- Port to connect to.
 *                             This corresponds to the host parameter
 *                             above.  Default is 8000
 *                         <li><i>pid</i> -- Process ID to attach to
 *                         </ul>
 * 
 * @param arguments        Command line arguments to pass to program
 * 
 * @param timeout          Timeout for connection and debugger
 *                         communication in milliseconds
 * 
 * @param debugger_path    Path to debugger executable
 * @param debugger_args    Additional arguments needed to invoke debugger
 * @param working_dir      Working directory to run program in
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <p>
 * To connect to the local host on port 8000 with a 10 second timeout:
 * </p>
 * <pre>
 *    int status = dbg_session_initialize(session_id, "", 8000, 10000, NULL, NULL);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @example 
 * <p>
 * To debug the 'hellow" program and pass it arguments "1 2 3 4"
 * with a 10 second timeout:
 * <p>
 * <pre>
 *    int status = dbg_session_initialize(session_id, "hellow", 0, "1 2 3 4", 10000, NULL, NULL);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_initialize(int session_id,
                           _str host_or_program, 
                           _str port_or_pid, 
                           _str arguments, int timeout, 
                           _str debugger_path, 
                           _str debugger_args, ...);

/**
 * Stop debugging and close the connection to the debugger.
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int status = dbg_session_finalize(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_finalize(int session_id);

/**
 * Stop the debugger and terminate execution.
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param exit_code        exit code for halted executable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_terminate(session_id, 0);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_terminate(int session_id, int exit_code);

/**
 * Detach from the debugging session and leave the application running.
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_detach(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_detach(int session_id);

/**
 * Detach from the remote debugging session and leave the
 * application suspended.
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_disconnect(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_disconnect(int session_id);

/**
 * Restart the program running under the debugger and step
 * into it.  Resets all breakpoints.  Note that this maintains
 * the existing connections to the debugger and vsdebugio
 * (where applicable).
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example To restart an active debug session.
 * <pre>
 *    int status = dbg_session_restart(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_restart(int session_id);


////////////////////////////////////////////////////////////////////////
// SENDING COMMANDS AND QUERYING RESULTS
////////////////////////////////////////////////////////////////////////
   
/**
 * Send the given command to the debugger and get the result
 * including both normal result ouput, and possible error output.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param command       debugger command to send
 * @param reply         command reply data
 * @param errmsg        output skimmed from stderr
 * @param parse_reply   parse the command reply, or just return string?
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    _str reply, errmsg;
 *    int status = dbg_session_do_command(session_id,
 *                                        "-insert-symbols vsapi.so",
 *                                        reply, errmsg);
 *    if (status) {
 *       _message_box("error = " :+ errmsg);
 *       return status;
 *    }
 *    _message_box("result = " :+ reply);
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_do_command(int session_id, _str command,
                           _str& reply, _str& errmsg,
                           bool parse_reply);

/**
 * Get the last error message returned by the debugger
 * from a failed command.  
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param errmsg        error message from debugger
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_error_message(int session_id, _str& errmsg);

/**
 * Send a output string directly to vsdebugio stdout.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param output_str    String to send to stdout.
 *
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_print_output(int session_id, _str output_str);

/**
 * Send an informational message string directly to vsdebugio stdout.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param info_str      String to send to stdout.
 * 
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_print_info(int session_id, _str info_str);

/**
 * Send an error string directly to vsdebugio stderr.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param error_str     String to send to stderr.
 * 
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_print_error(int session_id, _str error_str);

/**
 * Send input text directly to debugger. This will be
 * interpreted as debugee input by the debugger.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param input_str        String to send to debugger tty.
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_send_direct_input(int session_id, _str input_str);


////////////////////////////////////////////////////////////////////////
// DEBUGGER VERSION CHECKING
////////////////////////////////////////////////////////////////////////

/**
 * Get the version information for the debugger.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param description     Description of debugger and version
 * @param major_version   Major version number
 * @param minor_version   Minor version number
 * @param runtime_version Version of runtime environment
 * @param debugger_name   Name of debugger
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <p>
 * To get the version information for the debugger:
 * </p>
 * <pre>
 *    _str description;
 *    _str major_version;
 *    _str minor_version;
 *    _str runtime_version;
 *    _str debugger_name;
 *    int status = dbg_session_version(session_id, description,
 *                                     major_version, minor_version,
 *                                     runtime_version, debugger_name);
 *    if (status) {
 *       return status;
 *    }
 *    _message_box("description=" :+ description :+ "\n" :+
 *                 "major=" :+ major_version :+ "\n" :+
 *                 "minor=" :+ minor_version :+ "\n" :+
 *                 "runtime=" :+ runtime_version :+ "\n" :+
 *                 "debugger_name=" :+ debugger_name);
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_version(int session_id,
                        _str& description,
                        _str& major_version,
                        _str& minor_version,
                        _str& runtime_version,
                        _str& debugger_name);

/**
 * Test the given debugger executable for version compability.
 * This command is used outside of a debugging session to query
 * if a particular debugger executable is compatible.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param debugger_path   Path to debugger executable to test
 * @param version         On success, set to the version number
 * @param timeout         Connection timeout in milliseconds
 *
 * @return 1 on success, 0 on successful failure,
 *         &lt;0 on serious failure (not executable, file not found)
 *
 * @example To test the GDB supplied with cygwin, for example
 * <pre>
 *    _str version;
 *    int status = dbg_session_test_version(session_id,
 *                                          'C:\cygwin\bin\gdb.exe',
 *                                          version,10000);
 *    if (status==0) {
 *       _message_box("Inadaquate GDB version");
 *    } else if (status&lt;0) {
 *       _message_box("GDB executable failure: ":+get_message(status));
 *    } else {
 *       _message_box("GDB version is good");
 *    } 
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_test_version(int session_id,
                                    _str debugger_path,
                                    _str &version,
                                    int timeout);


////////////////////////////////////////////////////////////////////////
// COMPILE AND CONTINUE HOOK FUNCTION
////////////////////////////////////////////////////////////////////////

/**
 * Reload the given module into the debugger and continue debugging.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param file_names    Modules (class files) to reload
 * @param options       System-specific options
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_reload(session_id, "mylibrary.so", 0);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_reload(int session_id, _str file_names, int options);


////////////////////////////////////////////////////////////////////////
// SYSTEM AND SOURCE FILE PATH RESOLUTION
////////////////////////////////////////////////////////////////////////

/**
 * @param session_id    debugger session ID (1 .. max_session)
 * Get the user and system class paths for this debugging session.
 *
 * @param cwd             Set to the base directory or working directory
 * @param user            Set to user path, delimited by newlines
 * @param sys             Set to system path, delimited by newlines
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @example
 * <pre>
 *    _str cwd, user, sys;
 *    int status = dbg_session_get_paths(session_id, cwd, user, sys);
 *    if (status) {
 *       return status;
 *    }
 *    _message_box("cwd=" :+ cwd :+ "\n" :+
 *                 "user=" :+ user :+ "\n" :+
 *                 "sys=" :+ sys :+ "\n");
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_get_paths(int session_id,
                                 _str& cwd, _str& user, _str& sys);

/**
 * Resolve the path to the given source file using
 * debugger-specific lookup methods.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param file_name       source file name (with extension)
 * @param full_path       (reference) fully resolved, absolute path name
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_resolve_path(int session_id,
                                    _str file_name, _str& full_path);


////////////////////////////////////////////////////////////////////////
// SUSPEND AND RESUME
////////////////////////////////////////////////////////////////////////

/**
 * Suspend the entire debugging session or suspend a specific thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     "0" to suspend all threads, otherwise,
 *                      a specific thread ID to suspend.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To suspend all threads:
 * </p>
 * <pre>
 *    int status = dbg_session_suspend(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @example
 * <p>
 * To suspend only the "current" thread:
 * </p>
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    if (thread_id < 0) {
 *        return thread_id;
 *    }
 *    int status = dbg_session_suspend(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_suspend(int session_id, int thread_id);

/**
 * Continue execution of the for the entire debugging session,
 * or a specific thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     "0" to continue all threads, otherwise,
 *                      a specific thread to continue.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To continue all threads:
 * </p>
 * <pre>
 *    int status = dbg_session_resume(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @example
 * <p>
 * To continue only the "current" thread:
 * </p>
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    if (thread_id < 0) {
 *        return thread_id;
 *    }
 *    int status = dbg_session_resume(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_resume(int session_id, int thread_id);

/**
 * Interrupt the execution of a specific thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     ID of specific thread to interrupt
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To interpret the thread id 7:
 * </p>
 * <pre>
 *    int status = dbg_session_interrupt(session_id, 7);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_interrupt(int session_id, int thread_id);


////////////////////////////////////////////////////////////////////////
// STEPPING
////////////////////////////////////////////////////////////////////////

/**
 * If the next statement is a function call, step into the function,
 * otherwise, step to the next simple statement.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_step_into(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_step_into(int session_id, int thread_id, _str dbg_session_step_into='');

/**
 * Step over the current statement or function call.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_step_over(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_step_over(int session_id, int thread_id);

/**
 * Step out of the current function and back into the calling function.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_step_out(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_step_out(int session_id, int thread_id);

/**
 * If the next statement is a function call, step into the
 * function, even if it is a builtin or runtime function,
 * otherwise, step to the next simple statement.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_step_into_runtimes(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_step_into_runtimes(int session_id, int thread_id);

/**
 * Step by the minimal amount possible, for C++, this means step
 * into the assembly code for a statement.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_step_instruction(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_step_instruction(int session_id, int thread_id);

/**
 * Set the instruction pointer for the top frame in the given thread
 * to correspond to the given file/line/address.
 * NOTE:  typically the 'frame_id' is ignored,
 *        only the top frame can be modified.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID for instruction pointer to change
 * @param frame_id      Frame ID to modify instruction pointer for
 * @param class_name    name of class breakpoint is restricted to
 * @param method_name   name of method breakpoint is set in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number breakpoint occurs at
 * @param address       hex instruction address to set breakpoint at
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To move the instruction pointer to line 48:
 * </p>
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int frame_id = dbg_get_cur_frame(thread_id);
 * 
 *    _str file_name;
 *    int line_number=0;
 *    int status = dbg_get_frame_path(thread_id, frame_id,
 *                                    file_name, line_number);
 *    if (status) {
 *       return status;
 *    }
 * 
 *    int status = dbg_session_set_instruction_pointer(thread_id, frame_id,
 *                                                     "", "", file_name, 48);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_set_instruction_pointer(int session_id, 
                                        int thread_id, int frame_id,
                                        _str class_name, _str method_name,
                                        _str file_name, int line_number,
                                        _str address);


////////////////////////////////////////////////////////////////////////
// BREAKPOINTS
////////////////////////////////////////////////////////////////////////

/**
 * Enable the given breakpoint
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param breakpoint_id    Breakpoint to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_enable_breakpoint(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_enable_breakpoint(int session_id, int breakpoint_id);

/**
 * Disable the given breakpoint
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param breakpoint_id    Breakpoint to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_disable_breakpoint(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_disable_breakpoint(int session_id, int breakpoint_id);

/**
 * Probe if a breakpoint can be set on the given line and return the
 * corrected line, file, class, and method that the breakpoint would
 * be placed at.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_name    name of class breakpoint is in
 * @param method_name   name of function breakpoint is in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number in file breakpoint is in
 *
 * @return "fixed" line number &gt;0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To probe setting a breakpoint in a function name "xmain" in
 * a class named "Application":
 * </p>
 * <pre>
 *    int status = dbg_session_probe_breakpoint(session_id, 
 *                                              "Application", "xmain",
 *                                              "cfront.c", 0);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_probe_breakpoint(int session_id,
                             _str class_name, _str method_name,
                             _str file_name, int line_number);


////////////////////////////////////////////////////////////////////////
// WATCHPOINTS
////////////////////////////////////////////////////////////////////////

/**
 * Enable the given watchpoint
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param breakpoint_id    Watchpoint to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_enable_watchpoint(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_enable_watchpoint(int session_id, int breakpoint_id);

/**
 * Disable the given watchpoint
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param breakpoint_id    Watchpoint to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_disable_watchpoint(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_disable_watchpoint(int session_id, int breakpoint_id);


////////////////////////////////////////////////////////////////////////
// EXCEPTIONS
////////////////////////////////////////////////////////////////////////

/**
 * Enable the given exception
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param exception_id     Exception to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_enable_exception(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_enable_exception(int session_id, int exception_id);

/**
 * Disable the given exception
 *
 * @param session_id       debugger session ID (1 .. max_session)
 * @param exception_id     Exception to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_disable_exception(session_id, 1);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_disable_exception(int session_id, int exception_id);

   
////////////////////////////////////////////////////////////////////////
// PROBE FOR INCOMING EVENTS
////////////////////////////////////////////////////////////////////////

/**
 * Handle the next event from this debugging session's event queue.
 * This function returns '0' if the event was handled and disposed of.
 * Otherwise, it will return '1', indicating that you need to
 * handle the event yourself.
 *
 * @param session_id      debugger session ID (1 .. max_session)
 * @param event_kind      (reference) kind of event, including:
 *                        <UL>
 *                        <LI>"step"
 *                        <LI>"breakpoint"
 *                        <LI>"frame_pop"
 *                        <LI>"exception"
 *                        <LI>"user"
 *                        <LI>"thread_start"
 *                        <LI>"thread_stop"
 *                        <LI>"class_prepare"
 *                        <LI>"class_unload"
 *                        <LI>"class_load"
 *                        <LI>"field_access"
 *                        <LI>"field_modify"
 *                        <LI>"catch"
 *                        <LI>"method_entry"
 *                        <LI>"method_exit"
 *                        <LI>"vm_start"
 *                        <LI>"vm_stop"
 *                        </UL>
 * @param event_flags     (reference) Event handling flags,
 *                        what needs updating?
 *                        <UL>
 *                        <LI>VSDEBUG_EVENT_SUSPEND_ALL
 *                        <LI>VSDEBUG_EVENT_SUSPEND_THREAD
 *                        <LI>VSDEBUG_EVENT_GOTOPC
 *                        <LI>VSDEBUG_EVENT_CHANGE_THREAD
 *                        <LI>VSDEBUG_EVENT_UPDATE_CLASSES
 *                        <LI>VSDEBUG_EVENT_UPDATE_REGS
 *                        <LI>VSDEBUG_EVENT_UPDATE_MEMORY
 *                        <LI>VSDEBUG_EVENT_UPDATE_THREADS
 *                        <LI>VSDEBUG_EVENT_UPDATE_STACK
 *                        <LI>VSDEBUG_EVENT_UPDATE_VARS
 *                        </UL>
 * @param event_thread    (reference) ID of thread event occurred in
 * @param event_class     (reference) Class that event occurred in
 * @param breakpoint_id   (reference) ID of breakpoint for breakpoint events
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_handle_event(int session_id,
                             _str& event_kind,
                             int& event_flags,
                             int& event_thread,
                             _str& event_class,
                             int& breakpoint_id);


////////////////////////////////////////////////////////////////////////
// THREADS AND THREAD GROUPS
////////////////////////////////////////////////////////////////////////

/**
 * Update only the current thread running in this debugging session.
 * <p>
 * A thread has a thread name as well as a thread state.
 * <p>
 * Fundamentally, the responsibility of this method is to merely
 * identify the current thread and its system thread ID.
 * Optionally, it may gather the thread name and state information. 
 * <p> 
 * This method should not dispose of any old threads that were already 
 * found, it only needs to create or replace the thread for the current 
 * thread. 
 *  
 * @return 0 on success, &lt;0 on error.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @example
 * <pre>
 *    int status = dbg_session_update_current_thread(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 *  
 * @see dbg_session_update_threads 
 * @see dbg_session_update_thread_names
 * @see dbg_session_update_thread_states
 * 
 * @categories Debugger_Functions
 * @since 19.0
 */
extern int dbg_session_update_current_thread(int session_id);

/**
 * Update the list of threads running in this debugging session.
 * <p>
 * A thread has a thread name as well as a thread state.
 * <p>
 * Fundamentally, the responsibility of this method is to merely
 * identify the active threads and their system thread IDs.
 * Optionally, it may gather the thread names and state information.
 * If it does not, that work is deferred until updateThreadNames()
 * or updateThreadStates() is called. 
 * @return 0 on success, &lt;0 on error.
 * 
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @example
 * <pre>
 *    int status = dbg_session_update_threads(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 *  
 * @see dbg_session_update_current_thread 
 * @see dbg_session_update_thread_names
 * @see dbg_session_update_thread_states
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_threads(int session_id);

/**
 * Update the tree of thread groups in this debugging session.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int status = dbg_session_update_thread_groups(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @see dbg_session_update_threads
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_thread_groups(int session_id);

/**
 * Update the names of threads and thread groups in this
 * debugging session.
 * <p>
 * NOTE:  You must update the threads and thread groups first.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int status = dbg_session_update_threads(session_id);
 *    if (status) {
 *       return status;
 *    }
 *    status = dbg_session_update_thread_groups(session_id);
 *    if (status) {
 *       return status;
 *    }
 *    status = dbg_session_update_thread_names(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 *
 * @see dbg_session_update_threads
 * @see dbg_session_update_thread_groups
 * @see dbg_session_update_thread_states
 * 
 * @categories Debugger_Functions
 * @since 10.0
 * @deprecated Use dbg_session_update_threads() 
 */
extern int dbg_session_update_thread_names(int session_id);

/**
 * Update the status flags of all threads in this debugging session.
 * <p>
 * NOTE: You must update the threads first.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int status = dbg_session_update_threads(session);
 *    if (status) {
 *       return status;
 *    }
 *    status = dbg_session_update_thread_states(session);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 *
 * @see dbg_session_update_threads
 * @see dbg_session_update_thread_names
 * 
 * @categories Debugger_Functions
 * @since 10.0 
 * @deprecated Use dbg_session_update_threads() 
 */
extern int dbg_session_update_thread_states(int session_id);


////////////////////////////////////////////////////////////////////////
// CALL STACK
////////////////////////////////////////////////////////////////////////

/**
 * Update the top-most frame of the stack trace for the indicated thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to update stack for
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_update_stack_top(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 19.0
 */
extern int dbg_session_update_stack_top(int session_id, int thread_id);

/**
 * Update the stack trace for the indicated thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     Thread ID to update stack for
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <pre>
 *    int thread_id = dbg_get_cur_thread();
 *    int status = dbg_session_update_stack(session_id, thread_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_stack(int session_id, int thread_id);


////////////////////////////////////////////////////////////////////////
// LOCAL VARIABLES
////////////////////////////////////////////////////////////////////////

/**
 * Update the local variables for the specified stack
 * frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To update the local variables in the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_update_locals(session_id, thread_id, 1);
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_locals(int session_id, int thread_id, int frame_id);

/**
 * Expand the local variable at the given local variable path
 * for the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param local_path    path to local variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To expand the structured local at ID 5 under the local with
 * ID 8 in the current thread and the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_expand_local(session_id, thread_id, 1, "8 5");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_local(int session_id,
                             int thread_id, int frame_id,
                             _str local_path);

/**
 * Modify the value of the specified local variable
 * in the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param local_path    path to local variable to expand
 * @param new_value     value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To change the value of the the local with ID 8 in the
 * current thread and the top-most stack frame to 48:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_modify_local(session_id, thread_id, 1, "8", "48");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_modify_local(int session_id,
                             int thread_id, int frame_id,
                             _str local_path, _str new_value);

////////////////////////////////////////////////////////////////////////
// CLASS MEMBERS
////////////////////////////////////////////////////////////////////////

/**
 * Update the list of fields in the current class
 * for the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To update the class members in the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_update_members(session_id, thread_id, 1);
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_members(int session_id, int thread_id, int frame_id);

/**
 * Expand the member variable at the given member variable path
 * for the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param member_path   path to member variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To expand the structured member at ID 5 under the member with
 * ID 8 in the current thread and the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_expand_member(session_id, thread_id, 1, "8 5");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_member(int session_id,
                              int thread_id, int frame_id,
                              _str member_path);

/**
 * Modify the value of the specified member variable
 * in the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param local_path    path to local variable to expand
 * @param new_value     value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To change the value of the the class member with ID 8 in
 * the current thread and the top-most stack frame to 48:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_modify_member(session_id, thread_id, 1, "8", "48");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_modify_member(int session_id,
                              int thread_id, int frame_id,
                              _str member_path, _str new_value);


////////////////////////////////////////////////////////////////////////
// WATCHED VARIABLES
////////////////////////////////////////////////////////////////////////

/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param tab_number    which set of watches to update [1-4]
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To update the second watch set in the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_update_watches(session_id, thread_id, 1, 2);
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_watches(int session_id,
                               int thread_id, int frame_id, int tab_number);

/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param watch_path    path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To expand the structured field at ID 5 under the watch with
 * ID 8 in the current thread and the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_expand_watch(session_id, thread_id, 1, "8 5");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_watch(int session_id,
                             int thread_id, int frame_id,
                             _str watch_path);

/**
 * Modify the value of the specified watch expression
 * in the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param watch_path    path to local variable to expand
 * @param new_value     value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To change the value of the the watch with ID 8 in
 * the current thread and the top-most stack frame to 48:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_modify_watch(session_id, thread_id, 1, "8", "48");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_modify_watch(int session_id,
                             int thread_id, int frame_id,
                             _str watch_path, _str new_value);


////////////////////////////////////////////////////////////////////////
// AUTO-WATCHED VARIABLES
////////////////////////////////////////////////////////////////////////

/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To update all automatic watch variables in the top-most stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_update_auto_watches(session_id, thread_id, 1);
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_auto_watches(int session_id, int thread_id, int frame_id);

/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param autovar_path  path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To expand the structured field at ID 5 under the auto
 * watch with ID 8 in the current thread and the top-most
 * stack frame:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_expand_auto_watch(session_id, thread_id, 1, "8 5");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_auto_watch(int session_id,
                                  int thread_id, int frame_id,
                                  _str autovar_path);

/**
 * Modify the value of the specified auto watch expression
 * in the specified stack frame in the specified thread.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     index of thread in table
 * @param frame_id      index of frame in thread's stack
 * @param watch_path    path to local variable to expand
 * @param new_value     value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To change the value of the the auto watch with ID 8 in
 * the current thread and the top-most stack frame to 48:
 * </p>
 * <pre>
 *   int thread_id = dbg_get_cur_thread();
 *   int status = dbg_session_modify_auto_watch(session_id, thread_id, 1, "8", "48");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_modify_auto_watch(int session_id,
                                  int thread_id, int frame_id,
                                  _str autovar_path, _str new_value);


////////////////////////////////////////////////////////////////////////
// EXPRESSION EVALUATION
////////////////////////////////////////////////////////////////////////

/**
 * Parse a conditional expression in the current thread and frame.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     current thread
 * @param frame_id      current stack frame
 * @param expr          expression to parse
 *
 * @return 0 if the expression evaluates to false, 1 for true, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_eval_condition(int session_id,
                               int thread_id, int frame_id, _str expr);

/**
 * Parse an expression in the current thread and frame.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     current thread
 * @param frame_id      current stack frame
 * @param expr          expression to parse
 * @param value         (reference) set to value of expression
 *
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_eval_expression(int session_id,
                                int thread_id, int frame_id,
                                _str expr, _str& value);


////////////////////////////////////////////////////////////////////////
// CLASSES TABLE
////////////////////////////////////////////////////////////////////////

/**
 * Update the list of classes loaded by the system being debugged.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * 
 * @return 0 on success, &lt;0 on error
 *
 * @example
 * <pre>
 *    int status = dbg_session_update_classes(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_classes(int session_id);

/**
 * Update the items under a class recursively.  This includes
 * methods, static members, fields, and parent classes.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_path    List of class ID's and field ID's to expand
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @example
 * <p>
 * To expand the class with class ID 34:
 * </p>
 * <pre>
 *    int status = dbg_session_expand_class(session_id, "34");
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @example
 * <p>
 * To expand a structured static class member with ID 39 under class ID 34:
 * </p>
 * <pre>
 *    int status = dbg_session_expand_class(session_id, "34 39");
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_class(int session_id, _str class_path);

/**
 * Update the methods under a class.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_id      index of class in class table
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_methods(int session_id, int class_id);

/**
 * Update the fields under a class.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_fields(int session_id, int class_id);

/**
 * Update the nested classes under a class.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_nested(int session_id, int class_id);

/**
 * Update the parent classes under a class.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_expand_parents(int session_id, int class_id);

/**
 * Modify the value of the specified field of the specified class.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param field_path    path to field to modify
 * @param new_value     value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 * To change the value of the the field with ID 8 under the
 * class with ID 22 to the integer value 48:
 * </p>
 * <pre>
 *   int status = dbg_session_modify_field(session_id, "8 22", "48");
 *   if (status) {
 *      return status;
 *   }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_modify_field(int session_id, _str field_path, _str new_value);


////////////////////////////////////////////////////////////////////////
// DISASSEMBLY, REGISTERS AND MEMORY
////////////////////////////////////////////////////////////////////////

/**
 * Update the dissassembler output associated with the given stack frame.
 * 
 * @param file_name  Name of source file to disassemble
 * @param start_line First line to disassemble
 * @param num_lines  Number of lines in the source file
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = debugger->updateDisassembly("myfile.cpp", 1, 100);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_disassembly(int session_id, _str file_name,
                                   int start_line, int num_lines);

/**
 * Update the registers and register values.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param thread_id     thread ID to update registers for
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <pre>
 *    int status = dbg_session_update_registers(session_id);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_registers(int session_id, int thread_id);

/**
 * Update the watched memory region.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param address       Start address to dump
 * @param size          Number of bytes to dump
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 *    To examine the first 100 bytes of structure
 *    pointed to by a variable named 'p':
 * </p>
 * <pre>
 *    int status = dbg_session_update_memory(session_id, "p", 100);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 10.0
 */
extern int dbg_session_update_memory(int session_id, _str address, int size);

/**
 * Modify the watched memory region.
 *
 * @param session_id    debugger session ID (1 .. max_session)
 * @param address       Start address to modify
 * @param hexBytes      hexadecimal encoded bytes (bytes may be separated by spaces)
 * @param size          Number of bytes to modify
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @example
 * <p>
 *    To modify the first 8 bytes of structure
 *    pointed to by a variable named 'p':
 * </p>
 * <pre>
 *    int status = dbg_session_modify_memory(session_id, "p", "deadcafe 101101bb" 100);
 *    if (status) {
 *       return status;
 *    }
 * </pre>
 * 
 * @categories Debugger_Functions
 * @since 24.0
 */
extern int dbg_session_modify_memory(int session_id, _str address, _str hexBytes, int size);

/**
 * Update the memory region being monitored.
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      tree index to insert under (TREE_ROOT_INDEX)
 *
 * @return 0 on success, &lt;0 on error.
 */
extern int dbg_update_memory_tree(int tree_wid,int tree_index);

////////////////////////////////////////////////////////////////////////
// JAVA DEBUGGER CONNECTION TEST
////////////////////////////////////////////////////////////////////////

/**
 * Run java application from within the editor, using the
 * JNI interface to invoke the application.
 * <P>
 * Note that this function causes the application to be
 * executed in the same process space in a virtual machine
 * linked with the vsdebug.dll.  If the virtual machine
 * crashes, throws an unhandled exception, hangs, or is
 * terminated abnormally, it takes the editor down with it.
 * <P>
 * This function will most likely be removed before we ship.
 *
 * @param class_path      Class file or Jar file path for VM
 * @param server_name     Name of server
 * @param port            Port to connect at
 * @param class_name      Name of class application
 * @param entry_point     entry point within class (usually "main")
 *
 * @return 0 on success, &lt;0 on error.
 */
extern int dbg_start_java_session(_str class_path,_str server_name,
                           _str port,_str class_name,
                           _str entry_point);


////////////////////////////////////////////////////////////////////////
// DEBUGGER VIEWS
////////////////////////////////////////////////////////////////////////

/**
 * Update the debugger class browser tree with the
 * information retrieved by the debugger system.
 * The list has three columns:
 * <UL>
 * <LI>Class name
 * <LI>Outer class name (or package name)
 * <LI>Class status (loaded, prepred, unloaded)
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index of tree control to update under
 * @param class_path      Path to members under class to expand
 * @param hide_system     Hide system classes
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_class_tree(int tree_wid,int tree_index,_str class_path,bool hide_system=false);
/**
 * Update the list of classes with the information retrieved by
 * the debugger system.  The classes are inserted with their names only.
 *
 * @param list_wid        window ID of tree control
 * @param parent_class    (optional) last classes that derive from a this class
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_class_list(int list_wid, _str parent_class);
/**
 * Update the thread groups tree with the information
 * retrieved by the debugger system.
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      tree index to insert under (TREE_ROOT_INDEX)
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_group_tree(int tree_wid,int tree_index);
/**
 * Update the list of threads in the system.
 * The thread tree has four columns:
 * <UL>
 * <LI>Thread name
 * <LI>Group name
 * <LI>Thread status
 * <LI>Thread State
 * </UL>
 *
 * @param tree_wid        window ID of the tree control
 * @param tree_index      tree index to insert under (TREE_ROOT_INDEX)
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_thread_tree(int tree_wid,int tree_index);
/**
 * Update a list of suspended threads
 *
 * @param list_wid        List control window ID
 * @param only_suspended  Only included suspended threads?
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_thread_list(int list_wid, bool only_suspended);
/**
 * Update the list of functions on the current stack frame.
 * Each entry has two columns:
 * <UL>
 * <LI>The method name with parameter list
 * <LI>The class name
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      tree index to insert under (TREE_ROO_INDEX)
 * @param thread_id       thread ID to get stack dump for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_stack_tree(int tree_wid,int tree_index,
                          int thread_id);
/**
 * Update the list of functions in the stack dump.
 *
 * @param list_wid        List control to insert functions into
 * @param thread_id       thread ID to show stack dump for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_stack_list(int list_wid,int thread_id);
/**
 * Remove the imaginary lines representing the disassembly
 * for the given buffer.
 * 
 * @param editorctl     window ID of the editor control
 * @param file_name     name of buffer to update
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_editor_disassembly(int editorctl, _str file_name);
/**
 * Update the imaginary lines representing the disassembly
 * for the given buffer and editor control.
 * 
 * @param editorctl     window ID of the editor control
 * @param file_name     name of buffer to update
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_disassembly(int editorctl, _str file_name);
/**
 * Toggle whether the disassembly lines for the given file name
 * should be displayed or not.
 * 
 * @param file_name     source file to remove disassembly for
 * @param on_off        new setting for displaying disassembly
 *                      use -1 to query value
 * 
 * @return 'true' if the disassembly is to be displayed, false if not, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_toggle_disassembly(_str file_name, int on_off);
/**
 * Is the disassembly up to date for this source file?
 *
 * @return 'true' if the disassembly is up to date.
 *         Returns &lt;0 on error.
 * 
 * @param file_name   name of source file to check for disassembly
 * 
 * @categories Debugger_Functions
 */
extern int dbg_have_updated_disassembly(_str file_name);
/**
 * Update the list of local variables for the specified
 * stack frame within the given thread.
 * Each local has three columns:
 * <UL>
 * <LI>variable bitmap (variable or parameter)
 * <LI>local variable name
 * <LI>value of variable
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index to insert under (TREE_ROOT_INDEX)
 * @param thread_id       Thread ID to look at stack for
 * @param frame_id        ID of Stack frame to inspect
 * @param local_path      (optional) position to start updating tree at
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_locals_tree(int tree_wid,int tree_index,
                           int thread_id,int frame_id,_str local_path=null);
/**
 * Update the list of members of the current class for
 * the specified stack frame within the given thread.
 * Each entry has three columns:
 * <UL>
 * <LI>bitmap (variable or group)
 * <LI>name of variable
 * <LI>class name
 * <LI>value of variable (editable)
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      index to insert under (TREE_ROOT_INDEX)
 * @param thread_id       thread ID to inspect
 * @param frame_id        stack frame ID to get members in
 * @param member_path     (optional) position to start updating tree at
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_members_tree(int tree_wid,int tree_index,
                            int thread_id,int frame_id,_str member_path=null);
/**
 * Update the display of auto-watched variables.
 * Each variable has two columns:
 * <UL>
 * <LI>Name
 * <LI>Value
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index to insert variables at (TREE_ROOT_INDEX)
 * @param thread_id       index of thread
 * @param frame_id        index of stack frame
 * @param autovar_path    (optional) position to start updating tree at
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_autos_tree(int tree_wid,int tree_index,
                          int thread_id,int frame_id,
                          _str autovar_path=null);
/**
 * Update the display of manually-watched variables.
 * Each variable watch has two columns:
 * <UL>
 * <LI>Name
 * <LI>Value
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index to insert variables at (TREE_ROOT_INDEX)
 * @param thread_id       index of thread
 * @param frame_id        index of stack frame
 * @param tab_number      which tree tab the watch belongs to
 * @param watch_path      (optional) position to start updating tree at
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_watches_tree(int tree_wid,int tree_index,
                            int thread_id, int frame_id,
                            int tab_number, _str watch_path=null);
/**
 * Update the display of currently set breakpoints.
 * Each breakpoint has four columns:
 * <UL>
 * <LI>Class
 * <LI>Method
 * <LI>File
 * <LI>Line
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index to insert variables at (TREE_ROOT_INDEX)
 * @param rel_dir         Show breakpoint file names relative to this directory
 * @param pic_enabled     bitmap to display for an enabled breakpoint
 * @param pic_disabled    bitmap to display for a disabled breakpoint
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_breakpoints_tree(int tree_wid,int tree_index, _str rel_dir,
                                int pic_enabled, int pic_disabled);

/**
 * Update the display of currently set exception breakpoints.
 * Each exception breakpoint has two columns:
 * <UL>
 * <LI>Class name
 * <LI>Thrown, Caught, or Uncaught
 * </UL>
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      Index to insert variables at (TREE_ROOT_INDEX)
 * @param pic_enabled     bitmap to display for an enabled breakpoint
 * @param pic_disabled    bitmap to display for a disabled breakpoint
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_exceptions_tree(int tree_wid,int tree_index,
                               int pic_enabled, int pic_disabled);

/**
 * Update the list of registers and register values
 *
 * @param tree_wid        window ID of tree control
 * @param tree_index      tree index to insert under (TREE_ROOT_INDEX)
 * @param thread_id       thread ID to update registers for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_registers_tree(int tree_wid,int tree_index,int thread_id);

/**
 * Update the editor controls with the stack information
 *
 * @param thread_id       Thread ID to look at stack for
 * @param frame_id        ID of Stack frame to inspect
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_editor_stack(int thread_id, int frame_id);
/**
 * Update the editor controls with the breakpoints
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_update_editor_breakpoints();
/**
 * Indicate that all the views need to be refreshed.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_invalidate_views();
/**
 * Turn off debugging mode everywhere
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_editor();


////////////////////////////////////////////////////////////////////////
// JAVA JDWP INTEGRATION CALLBACKS
////////////////////////////////////////////////////////////////////////

/**
 * Initialize the JDWP connection to the virtual machine
 *
 * @param host_name       Name of host to connect to.  If the host name is the empty
 *                        string, assume 'localhost'.  In the future, it may also attempt
 *                        to get a shared memory connection when appropriate instead of
 *                        using the standard sockets to connect.
 * @param port_number     socket port number to connect to.  Default is 8000.
 * @param arguments       Arguments for running program, not used.
 * @param timeout         Connection timeout in milliseconds
 * @param unused_path     Unused JRE path variable
 * @param unused_args     Unused JRE arguments variable
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To connect to the local host on port 8000 with a 10 second timeout.
 * <PRE>
 *    int status=dbg_jdwp_initialize('',8000,'',10,null,null);
 *    if (status) {
 *       return(status);
 *    }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_initialize(_str host_name,_str port_number,_str arguments,int timeout,_str unused_path,_str unused_args);
/**
 * Close the JDWP connection and shut down the virtual machine.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To shut down the connection to the virtual machine:
 * <PRE>
 *    dbg_jdwp_finalize();
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_finalize();
/**
 * Get the version information for the debugger.
 *
 * @param description     Description of debugger implementation and version
 * @param major_version   Major version number
 * @param minor_version   Minor version number
 * @param runtime_version Version of Java Runtime Environment
 * @param debugger_name   Name of debugger
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To get the version information for the debugger:
 * <PRE>
 *    _str description;
 *    _str major_version;
 *    _str minor_version;
 *    _str runtime_version;
 *    _str debugger_name;
 *    dbg_jdwp_version(description,major_version,minor_version,runtime_version,debugger_name);
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_version(_str &description,
                     _str &major_version,
                     _str &minor_version,
                     _str &runtime_version,
                     _str &debugger_name);
/**
 * Update the list of classes loaded by the virtual machine.
 *
 * @return 0 on success, &lt;0 on error
 *
 * @example
 * <PRE>
 * status=dbg_jdwp_update_classes()
 * if (status) {
 *    return(status)
 * }
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_classes();
/**
 * Update the items under a class recursively.  This includes
 * methods, static members, fields, and parent classes.
 *
 * @param class_path    List of class ID's and field ID's to expand
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_class(_str class_path);
/**
 * Update the methods under a class.
 *
 * @param class_id      index of class in class table
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_methods(int class_id);
/**
 * Update the fields under a class.
 *
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_fields(int class_id);
/**
 * Modify the value of the specified field of the specified class.
 *
 * @param field_path      path to field to modify
 * @param new_value       value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_modify_field(_str field_path, _str new_value);
/**
 * Update the nested classes under a class.
 *
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_nested(int class_id);
/**
 * Update the parent classes under a class.
 *
 * @param class_id      index of class to get fields of
 *
 * @return 0 on success, &lt;0 on failure
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_parents(int class_id);

/**
 * Stop the virtual machine and terminate execution.
 *
 * @param exit_code       exit code for halted executable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_terminate(int exit_code);
/**
 * Detach from the virtual machine and leave the application running.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_detach();
/**
 * Reload the given module into the interpreter and continue debugging.
 *
 * @param file_names      Modules (class files) to reload
 * @param options         System-specific options
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_reload(_str file_names, int options);
/**
 * Get the user and system class paths for this debugging session.
 *
 * @param cwd             Set to the base directory or working directory
 * @param user            Set to user class path, delimited by newlines
 * @param sys             Set to boot class path, delimited by newlines
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_get_paths(_str &cwd, _str &user, _str &sys);
/**
 * Suspend the virtual machine, or a specific thread
 * within the virtual machine.
 *
 * @param thread_id       (optional) "0" to suspend all threads, otherwise, a
 *                        specific thread to suspend.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_suspend(int thread_id);
/**
 * Continue execution of the virtual machine, or a specific thread
 * within the virtual machine.
 *
 * @param thread_id       (optional) "0" to continue all threads, otherwise, a
 *                        specific thread to continue.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_continue(int thread_id);
/**
 * Interrupt the execution of a specific thread.
 *
 * @param thread_id       specific thread to interrupt
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_interrupt(int thread_id);
/**
 * Update the stack trace for the indicated thread
 *
 * @param thread_index  Thread ID to update stack for
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * int thread_id=dbg_get_cur_thread();
 * status=dbg_jdwp_update_stack(thread_id);
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_stack(int thread_id);
/**
 * Update the list of threads running in the virtual machine
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status=dbg_jdwp_update_threads();
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_threads();
/**
 * Update the three of thread groups in the virtual machine
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status = dbg_jdwp_update_threadgroups()
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_threadgroups();
/**
 * Update the names of threads and thread groups in the virtual machine.
 * You must update the threads and thread groups first.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status = dbg_jdwp_update_threadnames()
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 *
 * @see dbg_jdwp_update_threads
 * @see dbg_jdwp_update_threadgroups
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_threadnames();
/**
 * Update the status flags of all threads in the virtual machine.
 * You must update the threads first.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status = dbg_jdwp_update_threads()
 * if (status) {
 *    return(status);
 * }
 * status = dbg_jdwp_update_threadstates()
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 *
 * @see dbg_jdwp_update_threads
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_threadstates();
/**
 * Update the local variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_locals(int thread_id,int frame_id);
/**
 * Expand the local variable at the given local variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_local(int thread_id,int frame_id,_str local_path);
/**
 * Modify the value of the specified local variable
 * in the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 * @param new_value       value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_modify_local(int thread_id,int frame_id,
                          _str local_path, _str new_value);

/**
 * Update the list of fields in the current class
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_members(int thread_id,int frame_id);
/**
 * Expand the member variable at the given member variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param member_path     path to member variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_member(int thread_id,int frame_id,_str member_path);
/**
 * Modify the value of the specified member variable
 * in the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 * @param new_value       value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_modify_member(int thread_id,int frame_id,
                           _str member_path, _str new_value);

/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param tab_number      which set of watches to update [1-4]
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_watches(int thread_id,int frame_id,int tab_number);
/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param watch_path      path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_watch(int thread_id,int frame_id,_str watch_path);
/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_update_autos(int thread_id,int frame_id);
/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param autovar_path    path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_expand_autovar(int thread_id,int frame_id,_str autovar_path);
/**
 * Step out of the current function and back into the
 * calling function.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_step_out(int thread_id);
/**
 * Step over the current statement or function call.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_step_over(int thread_id);
/**
 * If the next statement is a function call, step into the function,
 * otherwise, step to the next simple statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_step_into(int thread_id);
/**
 * Step by the minimal amount possible, for C++, this means step
 * into the assembly code for a statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_step_instr(int thread_id);
/**
 * If the next statement is a function call, step into the function,
 * even if it is a builtin or runtime function, otherwise, step to
 * the next simple statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_step_deep(int thread_id);

/**
 * Disable the given breakpoint
 *
 * @param breakpoint_id       Breakpoint to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_disable_breakpoint(int breakpoint_id);
/**
 * Enable the given breakpoint
 *
 * @param breakpoint_id       Breakpoint to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_enable_breakpoint(int breakpoint_id);
/**
 * Probe if a breakpoint can be set on the given line and return the
 * corrected line, file, class, and method that the breakpoint would
 * be placed at.
 *
 * @param class_name    name of class breakpoint is in
 * @param method_name   name of function breakpoint is in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number in file breakpoint is in
 *
 * @return "fixed" line number &gt;0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_probe_breakpoint(_str class_name,_str method_name,
                              _str file_name, int line_number);

/**
 * Disable the given exception
 *
 * @param exception_id       Exception to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_disable_exception(int exception_id);
/**
 * Enable the given exception
 *
 * @param exception_id       Exception to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_enable_exception(int exception_id);

/**
 * Handle the next event from the virtual machine's event queue.
 * This function returns '0' if the event was handled and disposed of.
 * Otherwise, it will return '1', indicating that you need to
 * handle the event yourself.
 *
 * @param event_kind      (reference) kind of event, including:
 *                        <UL>
 *                        <LI>"step"
 *                        <LI>"breakpoint"
 *                        <LI>"frame_pop"
 *                        <LI>"exception"
 *                        <LI>"user"
 *                        <LI>"thread_start"
 *                        <LI>"thread_stop"
 *                        <LI>"class_prepare"
 *                        <LI>"class_unload"
 *                        <LI>"class_load"
 *                        <LI>"field_access"
 *                        <LI>"field_modify"
 *                        <LI>"catch"
 *                        <LI>"method_entry"
 *                        <LI>"method_exit"
 *                        <LI>"vm_start"
 *                        <LI>"vm_stop"
 *                        </UL>
 * @param event_flags     (reference) Event handling flags, what needs updating?
 *                        <UL>
 *                        <LI>VSDEBUG_EVENT_SUSPEND_ALL
 *                        <LI>VSDEBUG_EVENT_SUSPEND_THREAD
 *                        <LI>VSDEBUG_EVENT_GOTOPC
 *                        <LI>VSDEBUG_EVENT_CHANGE_THREAD
 *                        <LI>VSDEBUG_EVENT_UPDATE_CLASSES
 *                        <LI>VSDEBUG_EVENT_UPDATE_REGS
 *                        <LI>VSDEBUG_EVENT_UPDATE_MEMORY
 *                        <LI>VSDEBUG_EVENT_UPDATE_THREADS
 *                        <LI>VSDEBUG_EVENT_UPDATE_STACK
 *                        <LI>VSDEBUG_EVENT_UPDATE_VARS
 *                        </UL>
 * @param event_thread    (reference) ID of thread event occurred in
 * @param event_class     (reference) Class that event occurred in
 * @param breakpoint_id   (reference) ID of breakpoint for breakpoint events
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_handle_event(_str &event_kind,int &event_flags,
                          int &event_thread,_str &event_class,
                          int &breakpoint_id);

/**
 * Resolve the path to the given source file.
 * For Java, the searching is done by looking for source
 * files along the class path.  It will also check for
 * source files at directories one below the class path.
 *
 * @param file_name       source file name (with extension)
 * @param full_path       (reference) fully resolved, absolute path name
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_resolve_path(_str file_name,_str &full_path);

/**
 * Parse a conditional expression in the current thread and frame.
 *
 * @param thread_id  current thread
 * @param frame_id   current stack frame
 * @param expr       expression to parse
 *
 * @return 0 if the expression evaluates to false, 1 for true, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_jdwp_eval_condition(int thread_id,int frame_id,_str expr);


////////////////////////////////////////////////////////////////////////
// GDB INTEGRATION CALLBACKS
////////////////////////////////////////////////////////////////////////

/**
 * Send a output string directly to vsdebugio stdout.
 * 
 * @param str String to send to stdout.
 *
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_print_output(_str str);

/**
 * Send an informational message string directly to vsdebugio stdout.
 *
 * @param str String to send to stdout.
 * 
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_print_info(_str str);

/**
 * Send an error string directly to vsdebugio stderr.
 *
 * @param str String to send to stderr.
 * 
 * @return 0 on success, &lt;0 on error evaluating.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_print_error(_str str);

/**
 * Send input text directly to gdb tty. This will be interpreted as
 * debugee input by gdb.
 * 
 * @param str String to send to gdb tty.
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_input_direct(_str str);

/**
 * Initialize the GDB connection to the virtual machine
 *
 * @param prog_name       Program to debug under GDB, if we are attaching to a port
 *                        this parameter is still useful becuase it is needed for symbols.
 * @param pid_number      Process ID to attach to (0 means no attach)
 * @param arguments       Arguments to pass to program being debugged
 * @param timeout         Connection timeout in milliseconds
 * @param gdb_path        Path to 'gdb' executable
 * @param gdb_args        Supplemental arguments used when starting up GDB
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To debug the 'hellow" program and pass it arguments "1 2 3 4"
 *          with a 10 second timeout.
 * <PRE>
 *    int status=dbg_gdb_initialize('hellow',0,"1 2 3 4",10,null,null);
 *    if (status) {
 *       return(status);
 *    }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_initialize(_str prog_name,_str pid_number,_str arguments,int timeout,_str gdb_path,_str gdb_args);
/**
 * Test the given GDB executable for version compability.
 * The SlickEdit GDB integration requires a GDB of at least
 * version 5.1 with the MI command interface available.
 *
 * @return 1 on success, 0 on successful failure,
 *         &lt;0 on serious failure (not executable, file not found)
 *
 * @param gdb_path   Name of application to debug, specifies path to executable.
 * @param version    On success, set to the version number of the GDB program.
 * @param timeout    Connection timeout in milliseconds.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To test the GDB supplied with cygwin, for example
 * <PRE>
 *    int status=dbg_gdb_test_version('C:\cygwin\bin\gdb.exe',"",10000);
 *    if (status==0) {
 *       _message_box("Inadaquate GDB version");
 *    } else if (status&lt;0) {
 *       _message_box("GDB executable failure: ":+get_message(status));
 *    }
 * </PRE>
 */
extern int dbg_gdb_test_version(_str gdb_path, _str &version, int timeout);
/**
 * Close the GDB connection and shut down the virtual machine.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To shut down the connection to the virtual machine:
 * <PRE>
 *    dbg_gdb_finalize();
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_finalize();
/**
 * Detach from the running process and leave the application running.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_detach();
/**
 * Restart the program running under GDB and step into it.
 * Resets all breakpoints.  Note that this maintains the
 * existing connections to GDB and vsdebugio.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To restart an active debug session.
 * <PRE>
 *    int status=dbg_gdb_restart();
 *    if (status) {
 *       return(status);
 *    }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_restart();
/**
 * Send the given command to the debugger and get the result
 * including both normal result ouput, and possible error output.
 *
 * @param command          GDB command to send
 * @param reply            command reply data
 * @param errmsg           output skimmed from stderr
 * @param parse_reply      If false, 'reply' is a string,
 *                         otherwise it is an array/hash table
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_do_command(_str command, var reply, _str &errmsg, bool parse_reply);
/**
 * Get the version information for the debugger.
 *
 * @param description     Description of debugger implementation and version
 * @param major_version   Major version number
 * @param minor_version   Minor version number
 * @param runtime_version Version of Java Runtime Environment
 * @param debugger_name   Name of debugger
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example To get the version information for the debugger:
 * <PRE>
 *    _str description;
 *    _str major_version;
 *    _str minor_version;
 *    _str runtime_version;
 *    _str debugger_name;
 *    dbg_gdb_version(description,major_version,minor_version,runtime_version,debugger_name);
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_version(_str &description,
                     _str &major_version,
                     _str &minor_version,
                     _str &runtime_version,
                     _str &debugger_name);

/**
 * Stop the virtual machine and terminate execution.
 *
 * @param exit_code       exit code for halted executable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_terminate(int exit_code);
/**
 * Suspend the virtual machine, or a specific thread
 * within the virtual machine.
 *
 * @param thread_id       (optional) "0" to suspend all threads, otherwise, a
 *                        specific thread to suspend.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_suspend(int thread_id);
/**
 * Continue execution of the virtual machine, or a specific thread
 * within the virtual machine.
 *
 * @param thread_id       (optional) "0" to continue all threads, otherwise, a
 *                        specific thread to continue.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_continue(int thread_id);
/**
 * Interrupt the execution of a specific thread.
 *
 * @param thread_id       specific thread to interrupt
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_interrupt(int thread_id);
/**
 * Update the stack trace for the indicated thread
 *
 * @param thread_index  Thread ID to update stack for
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * int thread_id=dbg_get_cur_thread();
 * status=dbg_gdb_update_stack(thread_id);
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_stack(int thread_id);
/**
 * Update the list of threads running in the virtual machine
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status=dbg_gdb_update_threads();
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_threads();
/**
 * Update the names of threads and thread groups in the virtual machine.
 * You must update the threads and thread groups first.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status = dbg_gdb_update_threadnames()
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 *
 * @see dbg_gdb_update_threads
 * @see dbg_gdb_update_threadgroups
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_threadnames();
/**
 * Update the status flags of all threads in the virtual machine.
 * You must update the threads first.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @example
 * <PRE>
 * status = dbg_gdb_update_threads()
 * if (status) {
 *    return(status);
 * }
 * status = dbg_gdb_update_threadstates()
 * if (status) {
 *    return(status);
 * }
 * </PRE>
 *
 * @see dbg_gdb_update_threads
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_threadstates();
/**
 * Update the registers and register values.
 *
 * @param thread_id   thread ID to update registers for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_registers(int thread_id);
/**
 * Update the watched memory region.
 *
 * @param address    Start address to dump
 * @param size       Number of bytes to dump
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_memory(_str address, int size);
/**
 * Update the local variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_locals(int thread_id,int frame_id);
/**
 * Expand the local variable at the given local variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_expand_local(int thread_id,int frame_id,_str local_path);
/**
 * Modify the value of the specified local variable
 * in the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 * @param new_value       value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_modify_local(int thread_id,int frame_id,
                          _str local_path, _str new_value);

/**
 * Update the list of fields in the current class
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_members(int thread_id,int frame_id);
/**
 * Expand the member variable at the given member variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param member_path     path to member variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_expand_member(int thread_id,int frame_id,_str member_path);
/**
 * Modify the value of the specified member variable
 * in the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param local_path      path to local variable to expand
 * @param new_value       value to set variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_modify_member(int thread_id,int frame_id,
                           _str member_path, _str new_value);

/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param tab_number      which set of watches to update [1-4]
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_watches(int thread_id,int frame_id,int tab_number);
/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param watch_path      path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_expand_watch(int thread_id,int frame_id,_str watch_path);
/**
 * Update the watched variables for the specified stack
 * frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_update_autos(int thread_id,int frame_id);
/**
 * Expand the watched variable at the given variable path
 * for the specified stack frame in the specified thread.
 *
 * @param thread_id       index of thread in table
 * @param frame_id        index of frame in thread's stack
 * @param autovar_path    path to watched variable to expand
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_expand_autovar(int thread_id,int frame_id,_str autovar_path);
/**
 * Step out of the current function and back into the
 * calling function.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_step_out(int thread_id);
/**
 * Step over the current statement or function call.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_step_over(int thread_id);
/**
 * If the next statement is a function call, step into the function,
 * otherwise, step to the next simple statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_step_into(int thread_id);
/**
 * Step by the minimal amount possible, for C++, this means step
 * into the assembly code for a statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_step_instr(int thread_id);
/**
 * If the next statement is a function call, step into the function,
 * even if it is a builtin or runtime function, otherwise, step to
 * the next simple statement.
 *
 * @param thread_id       Thread ID to step
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_step_deep(int thread_id);

/**
 * Set the instruction pointer for the top frame in the given thread
 * to correspond to the given file/line/address.
 * NOTE:  the 'frame_id' is ignored, only the top frame can be modified.
 * 
 * @param thread_id     Thread ID for instruction pointer to change
 * @param frame_id      Frame ID to modify instruction pointer for
 * @param class_name    name of class breakpoint is restricted to
 * @param method_name   name of method breakpoint is set in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number breakpoint occurs at
 * @param address       hex instruction address to set breakpoint at
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_set_instruction_pointer(int thread_id, int frame_id,
                                    _str class_name, _str method_name,
                                    _str file_name, int line_number, _str address);

/**
 * Disable the given breakpoint
 *
 * @param breakpoint_id       Breakpoint to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_disable_breakpoint(int breakpoint_id);
/**
 * Enable the given breakpoint
 *
 * @param breakpoint_id       Breakpoint to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_enable_breakpoint(int breakpoint_id);
/**
 * Probe if a breakpoint can be set on the given line and return the
 * corrected line, file, class, and method that the breakpoint would
 * be placed at.
 *
 * @param class_name    name of class breakpoint is in
 * @param method_name   name of function breakpoint is in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number in file breakpoint is in
 *
 * @return "fixed" line number &gt;0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_probe_breakpoint(_str class_name,_str method_name,
                              _str file_name, int line_number);

/**
 * Disable the given exception
 *
 * @param exception_id       Exception to disable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_disable_exception(int exception_id);
/**
 * Enable the given exception
 *
 * @param exception_id       Exception to enable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_enable_exception(int exception_id);

/**
 * Handle the next event from the virtual machine's event queue.
 * This function returns '0' if the event was handled and disposed of.
 * Otherwise, it will return '1', indicating that you need to
 * handle the event yourself.
 *
 * @param event_kind      (reference) kind of event, including:
 *                        <UL>
 *                        <LI>"step"
 *                        <LI>"breakpoint"
 *                        <LI>"frame_pop"
 *                        <LI>"exception"
 *                        <LI>"user"
 *                        <LI>"thread_start"
 *                        <LI>"thread_stop"
 *                        <LI>"class_prepare"
 *                        <LI>"class_unload"
 *                        <LI>"class_load"
 *                        <LI>"field_access"
 *                        <LI>"field_modify"
 *                        <LI>"catch"
 *                        <LI>"method_entry"
 *                        <LI>"method_exit"
 *                        <LI>"vm_start"
 *                        <LI>"vm_stop"
 *                        </UL>
 * @param event_flags     (reference) Event handling flags, what needs updating?
 *                        <UL>
 *                        <LI>VSDEBUG_EVENT_SUSPEND_ALL
 *                        <LI>VSDEBUG_EVENT_SUSPEND_THREAD
 *                        <LI>VSDEBUG_EVENT_GOTOPC
 *                        <LI>VSDEBUG_EVENT_CHANGE_THREAD
 *                        <LI>VSDEBUG_EVENT_UPDATE_CLASSES
 *                        <LI>VSDEBUG_EVENT_UPDATE_REGS
 *                        <LI>VSDEBUG_EVENT_UPDATE_MEMORY
 *                        <LI>VSDEBUG_EVENT_UPDATE_THREADS
 *                        <LI>VSDEBUG_EVENT_UPDATE_STACK
 *                        <LI>VSDEBUG_EVENT_UPDATE_VARS
 *                        </UL>
 * @param event_thread    (reference) ID of thread event occurred in
 * @param event_class     (reference) Class that event occurred in
 * @param breakpoint_id   (reference) ID of breakpoint for breakpoint events
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_handle_event(_str &event_kind,int &event_flags,
                          int &event_thread,_str &event_class,
                          int &breakpoint_id);

/**
 * Resolve the path to the given source file.
 * For Java, the searching is done by looking for source
 * files along the class path.  It will also check for
 * source files at directories one below the class path.
 *
 * @param file_name       source file name (with extension)
 * @param full_path       (reference) fully resolved, absolute path name
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_resolve_path(_str file_name,_str &full_path);

/**
 * Parse a conditional expression in the current thread and frame.
 *
 * @param thread_id  current thread
 * @param frame_id   current stack frame
 * @param expr       expression to parse
 *
 * @return 0 if the expression evaluates to false, 1 for true, &lt;0 on error.
 * 
 * @deprecated Use the dbg_session_* callbacks.
 */
extern int dbg_gdb_eval_condition(int thread_id,int frame_id,_str expr);



////////////////////////////////////////////////////////////////////////
// DEBUGGER MODEL
////////////////////////////////////////////////////////////////////////

/**
 * @return Return the index of current thread being inspected, 0 if not set.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_cur_thread();
/**
 * Sets the current thread index as specified.
 *
 * @param thread_id  New current thread index
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_cur_thread(int thread_id);
/**
 * Sets the current thread index to the n'th suspended thread.
 *
 * @param thread_id  New current thread index
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_cur_suspended_thread(int thread_id);
/**
 * @param thread_id     index of thread to get current frame of
 *
 * @return Return the index of current stack frame, 0 if not set.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_cur_frame(int thread_id);
/**
 * Sets the current frame index as specified.
 *
 * @param thread_id  Thread to set frame ID for
 * @param frame_id   New current frame index
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_cur_frame(int thread_id,int frame_id);
/**
 * @return Return the number of system registers.
 *
 * @param thread_id   thread ID get registers for
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_registers(int thread_id);
/**
 * @return Return the number of classes in the class table
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_classes();
/**
 * @return Return the number of threads in the current running process.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_threads();
/**
 * @return Return the number of suspended threads in the current process.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_suspended();
/**
 * @return Return the number of frames on the stack for the current thread.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_frames(int thread_id);
/**
 * @return Return the number of disassembled files.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_disassembled_files();
/**
 * @param source_file   disassembled source file
 *
 * @return Return the number of disassembly lines for the given file.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_disassembly_lines(_str source_file);
/**
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 *
 * @return Return the number of locals on the stack for the current stack frame.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_locals(int thread_id,int frame_id);
/**
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 *
 * @return Return the number of field in 'this' for the current stack frame.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_members(int thread_id,int frame_id);
/**
 * @return Return the number of watched variables.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_watches();
/**
 * @return Return the number of auto-variables.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_autos(int thread_id,int frame_id);
/**
 * @return Return the number of breakpoints.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_breakpoints();
/**
 * @return Return the number of exception breakpoints.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_exceptions();
/**
 * @param class_id   index of class to get information for
 *
 * @return Return the number of fields in the specified class.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_fields(int class_id);
/**
 * @param class_id   index of class in class table
 *
 * @return Return the number of methods in the specified class
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_methods(int class_id);

/**
 * Get the details about a register.
 *
 * @param thread_id  thread ID to get registers for
 * @param reg_id     index of register in the register table
 * @param name       (reference) name of register
 * @param value      (reference) value stored in register
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_register(int thread_id,int reg_id,_str &name,_str &value);
/**
 * Set the value of a system register.
 *
 * @param thread_id  thread ID to update registers for
 * @param reg_id     index of register in register table
 * @param value      new value to set register to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_register(int thread_id,int reg_id, _str value);
/**
 * Get the basic information about the indicated class
 *
 * @param class_path    index path of class in class table
 * @param name          (reference) name of class
 * @param outer_class   (reference) outer class name
 * @param signature     (reference) signature of class (type)
 * @param file_name     (reference) source file that class is in
 * @param flags         (reference) bitset of DBG_FLAGS_
 * @param class_loader  (reference) class loader
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_class(_str class_path,_str &name,
                  _str &outer_class,_str &signature,
                  _str &file_name,int &flags,_str &loader);
/**
 * Find the class with the given class name.
 *
 * @param class_name     name of class to look for
 * @param name_only      find first match using class name only
 * @param start_id       class ID to start searching at
 *
 * @return class ID > 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_find_class(_str class_name,int name_only,int start_id=0);
/**
 * Collapse the information below a specified class or class path
 *
 * @param class_path    class ID path to class to collapse.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_collapse_class(_str class_path);
/**
 * Get the information about the field at the given index in the field table
 * of the given class.
 *
 * @param class_id  index of class in class table
 * @param field_id  index of field in field table of class
 * @param name      (reference) name of field
 * @param signature (reference) set to type of field
 * @param value     (reference) set to value of field
 * @param flags     (reference) set to bitset of DEBUG_MODEL_FLAGS_
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_field(int class_id,int field_id,_str &name,
                  _str &signature,_str &value,int &flags);
/**
 * Set the value of a field in a class
 *
 * @param class_id   index of class in class table
 * @param field_id   index of field within class
 * @param value      (reference) new value of field
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_field(int class_id, int field_id, _str value);
/**
 * Get the details about a method of a class.
 *
 * @param class_id   index of class in class table
 * @param method_id  index of method in list of classes within specified class
 * @param name       (reference) name of method
 * @param class_name (reference) name of class
 * @param signature  (reference) parameters of method
 * @param return_type (reference) return type of method
 * @param file_name  (reference) source file containing this method
 * @param flags      (reference) bitset of DEBUG_MODEL_FLAG_*
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_method(int class_id,int method_id,
                   _str &name,_str &class_name,
                   _str &signature,_str &return_type,
                   _str &file_name,int &flags);
/**
 * Get information about a nested types within a class
 *
 * @param class_id    index of class in class table
 * @param type_id     index of nested type within class
 * @param nested_type (reference) information about nested type
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_nested_type(int class_id, int type_id,
                        int &nested_id);
/**
 * Get the name of the specified interface implemented
 * by the given class.
 *
 * @param class_id   index of class in class table
 * @param parent_id  index of interface
 * @param class_name (referene) name of parent class
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_parent_interface(int class_id, int parent_id,
                             _str &class_name);
/**
 * Get the name of the specified parent class
 *
 * @param class_id   index of class in class table
 * @param parent_id  index of parent class (usually '1')
 * @param class_name (referene) name of parent class
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_parent_class(int class_id, int parent_id,
                         _str &class_name);
/**
 * Get the details about a thread.
 *
 * @param thread_id  index of suspend thread in thread table
 * @param name       (reference) thread name
 * @param group_name (reference) thread group name
 * @param flags      (reference) bitset of DEBUG_MODEL_THREAD_FLAGS_*
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_thread(int thread_id,
                   _str &name,_str &group_name,int &flags);
/**
 * @return 'true' if the current thread is up to date.
 *         Returns &lt;0 on error.
 * <p>
 * {@link dbg_clear_threads()} will mark the threads as stale.
 * 
 * @see dbg_clear_threads
 * @see dbg_add_thread
 * @see dbg_get_thread
 * 
 * 
 * @categories Debugger_Functions
 */
extern int dbg_has_updated_current_thread();
/**
 * @return 'true' if the threads are up to date.
 *         Returns &lt;0 on error.
 * <p>
 * {@link dbg_clear_threads()} will mark the threads as stale.
 * 
 * @see dbg_clear_threads
 * @see dbg_add_thread
 * @see dbg_get_thread
 * 
 * 
 * @categories Debugger_Functions
 */
extern int dbg_have_updated_threads();
/**
 * Add a thread to the debugger model
 * 
 * @param thread_id Thread id from native debugger.
 *                  VSE will have its own index
 *                  to refer to this thread by
 * @param thread_flags Combination of 
 * <UL>
 *    <LI>VSDEBUG_THREAD_FLAG_ZOMBIE
 *    <LI>VSDEBUG_THREAD_FLAG_RUNNING
 *    <LI>VSDEBUG_THREAD_FLAG_SLEEPING
 *    <LI>VSDEBUG_THREAD_FLAG_MONITOR
 *    <LI>VSDEBUG_THREAD_FLAG_WAIT
 *    <LI>VSDEBUG_THREAD_FLAG_SUSPENDED
 *    <LI>VSDEBUG_THREAD_FLAG_FROZEN
 * </UL>
 * @param thread_name Thread name from native debugger
 * @param parent_group
 * 
 * @return thread_id > 0 on success, < 0 on error.
 * 
 * @example
 * <pre>
 * int dbg_mydebugger_update_threads()
 * {
 *    dbg_clear_threads();
 *    dbg_add_thread(1,VSDEBUG_THREAD_FLAG_SUSPENDED,"main",0);
 *    dbg_add_thread(2,VSDEBUG_THREAD_FLAG_SUSPENDED,"cleanup",0);
 *    dbg_add_thread(3,VSDEBUG_THREAD_FLAG_SUSPENDED,"gc",0);
 *    return 0;
 * }
 * </pre>
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_thread(int thread_id, int thread_flags,
                   _str thread_name, int parent_group);

/**
 * Get the details about a suspended thread.
 * Note that the index of a suspended thread is not technically
 * the same as the index of that same thread on the complete
 * threads table.  It is the n'th thread on the threads table
 * which has the 'suspended' flag set.
 *
 * @param thread_id  index of suspend thread in thread table
 * @param name       (reference) thread name
 * @param group_name (reference) thread group name
 * @param flags      (reference) bitset of DEBUG_MODEL_THREAD_FLAGS_*
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_suspended(int thread_id,_str &name,
                      _str &group_name,int &flags);
/**
 * Get the details about the specified thread group.
 *
 * @param threadgroup_id index of thread group in table
 * @param name           (reference) name of thread group
 * @param group_name     (reference) name of parent thread group
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_threadgroup(int threadgroup_id,
                        _str &name,_str &group_name);

/**
 * Get the details about the given stack frame
 *
 * @param thread_id       index of thread to get stack frame from
 * @param frame_id        index of frame in stack frame list
 * @param method_name     (reference) name of method on stack frame
 * @param signature       (reference) method signature
 * @param return_type     (reference) return type of method
 * @param class_name      (reference) name of class on stack frame
 * @param file_name       (reference) name of file that stack frame is positioned at
 * @param line_number     (reference) line number that stack frame is positioned at
 * @param address         (reference) address of current instruction in stack frame
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_frame(int thread_id,
                  int frame_id,
                  _str &method_name,
                  _str &signature,
                  _str &return_type,
                  _str &class_name,
                  _str &file_name,
                  int &line_number,
                  _str &address);

/**
 * Get the details about file and line number for the the given stack frame.
 *
 * @param thread_id       index of thread to get stack frame from
 * @param frame_id        index of frame in stack frame list
 * @param file_name       (reference) name of file that stack frame is positioned at
 * @param line_number     (reference) line number that stack frame is positioned at
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_frame_path(int thread_id,
                       int frame_id,
                       _str &file_name,
                       int &line_number);

/**
 * Save the resolved (full) file path to the given stack frame.
 *
 * @param thread_id       index of thread to get stack frame from
 * @param frame_id        index of frame in stack frame list
 * @param full_path       path to file that stack frame is positioned at
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_frame_path(int thread_id, int frame_id, _str full_path);

/**
 * Return the i'th source source file path
 *
 * @param i          index of source directory to get, first index is '1'
 * @param source_dir (reference) set to source directory name
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_source_dir(int i, _str &source_dir);
/**
 * Add another source directory
 *
 * @param source_dir directory to add to list
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_source_dir(_str source_dir);
/**
 * @return Return the number of source file paths stored, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_dirs();
/**
 * Attempt to quickly resolve the path to the given
 * source file.  First it checks the "source file" to
 * "resolved file" cached mapping.  If that fails, it
 * tries to find the file in one of the source dirs.
 *
 * @param file_name       source file name (with extension)
 * @param full_path       (reference) fully resolved, absolute path name
 *
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_resolve_path(_str file_name, _str &full_path);
/**
 * Save the fact that 'source_file' maps to 'full_path'.
 *
 * @param file_name       source file name (with extension)
 * @param full_path       fully resolved, absolute path name
 *
 * @return 0 on success, &lt;0 on error
 *
 * @deprecated This function is obsolete, as of 7.0.1
 * 
 * @categories Debugger_Functions
 */
extern int dbg_cache_resolved_path(_str file_name, _str full_path);

/**
 * Return the i'th system runtime exclude expression
 *
 * @param i          index of runtime expr to get, first index is '1'
 * @param expr       (reference) set to runtime exclude name
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_runtime_expr(int i, _str &expr);
/**
 * Add another runtime exclude expression
 *
 * @param expr  String describing system exclude
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_runtime_expr(_str expr);
/**
 * @return Return the number of runtime excludes stored, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_runtimes();
/**
 * Check if the given item is in the system runtime exclude list
 *
 * @param name  String to check (usually a package/class name)
 *
 * @return 1 if excluded, 0 otherwise
 * 
 * @categories Debugger_Functions
 */
extern int dbg_is_runtime_expr(_str name);

/**
 * Get the details about a disassembled source line.
 *
 * @param source_file   source file
 * @param line_number   line number
 * @param addresses     (reference) array of instruction addresses
 * @param instructions  (reference) array of disassembled instructions
 * @param func_names    (reference) array of function names
 * @param offsets       (reference) array of function offsets
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_disassembly_line(_str source_file, int line_number,
                             _str (&addresses)[], _str (&instructions)[],
                             _str (&func_names)[], _str (&offsets)[]);

/**
 * Add the disassembly for the indicated line in the indicated source file.
 *
 * @param source_file   source file the line is in
 * @param line_number   line number to disassemble
 * @param addresses     (reference) array of instruction addresses
 * @param instructions  (reference) array of disassembled instructions
 * @param func_names    (reference) array of function names
 * @param offsets       (reference) array of function offsets
 * 
 * @return the line ID > 0 on success, < 0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_disassembly_line(_str source_file, int line_number,
                             _str (&addresses)[], _str (&instructions)[],
                             _str (&func_names)[], _str (&offsets)[]);
/**
 * Find the line and offset of the instruction corresponding
 * to the given program counter address.
 *
 * @param source_file   source file
 * @param address       program counter address
 * @param line_number   (reference) set to line number
 * @param inst_offset   (reference) set to line offset
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_find_disassembly_line(_str source_file, _str address,
                              int &line_number, int &inst_offset);

/**
 * Get the details about a local variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param local_path  path to local in list of local variables
 * @param name        (reference) name of local
 * @param class_name  (reference) name of class that we are in
 * @param signature   (reference) type of local variable
 * @param flags       (reference) set to bitset of DEBUG_MODEL_FLAGS_
 * @param value       (reference) value of variable
 * @param line_number (reference) line number that it is declared at
 * @param is_in_scope (reference) is the variable in scope?
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_local(int thread_id,
                  int frame_id,
                  _str local_path,
                  _str &name,
                  _str &class_name,
                  _str &signature,
                  int &flags,
                  _str &value,
                  int &line_number,
                  int &is_in_scope,
                  _str &raw_value);

/**
 * Set the value of a local variable in the current stack frame.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param local_path  path to local in list of local variables
 * @param value       new value to set local variable to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_local(int thread_id,int frame_id,
                  _str local_path, _str value);
/**
 * Collapse all the nodes under the given local variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param local_path  path to local in list of local variables
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_collapse_local(int thread_id,int frame_id,_str local_path);

/**
 * Get the details about a member of 'this' object.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param member_path path to member in list of member variables
 * @param name        (reference) name of member
 * @param class_name  (reference) name of class the member is in
 * @param signature   (reference) type of variable
 * @param value       (reference) value of variable
 * @param flags       (reference) set to bitset of DEBUG_MODEL_FLAGS_*
 * @param is_in_scope (reference) is the variable in scope?
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_member(int thread_id,int frame_id,_str member_path,
                   _str &name,_str &class_name,
                   _str &signature,int &flags,_str &value, _str &raw_value);
/**
 * Set the value of a member of 'this' object.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param member_path path to member in list of member variables
 * @param value       new value to set member to
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_member(int thread_id,int frame_id,
                   _str member_path, _str value);
/**
 * Collapse all the nodes under the given member variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param member_path path to member in list of member variables
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_collapse_member(int thread_id,int frame_id,_str member_path);

/**
 * Get the details about a watched variable.
 *
 * @param thread_id     (optional, use 0) index of thread
 * @param frame_id      (optional, use 0) index of stack frame
 * @param watch_id      index of variable in list of watches
 * @param tab_number    (reference) [1-4], which watch tree to insert into
 * @param expr          (reference) expression to watch
 * @param context_name  (reference) the context to evaluate watch in
 * @param value         (reference) display value of variable
 * @param expandable    (reference) set to 1 if this node is expandable
 * @param base          (reference) base to display this variable's value in
 * @param raw_value     (reference) raw value of variable 
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_watch(int thread_id,int frame_id,int watch_id,
                  int &tab_number, _str &expr,
                  _str &context_name, _str &value, int &expandable,
                  int &base, _str &raw_value, _str &type);
/**
 * Get the details about a variable or expanded watch variable
 * 
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param watch_path  path to auto-watch variable in tree
 * @param name        (reference) name of variable
 * @param class_name  (reference) name of class the member is in
 * @param signature   (reference) type of variable
 * @param value       (reference) display value of variable
 * @param flags       (reference) set to bitset of DEBUG_MODEL_FLAGS_* 
 * @param raw_value   (reference) raw value of variable 
 * 
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_watch_info(int thread_id,int frame_id,_str watch_path,
                       _str &name, _str &class_name, _str &signature,
                       _str &value, int &flags, _str &raw_value);

/**
 * Collapse all the nodes under the given watched variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param watch_path  path to member in list of watch variables
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_collapse_watch(int thread_id,int frame_id,_str watch_path);

/**
 * Are the auto-watch variables up-to-date for the given
 * thread and frame?
 *
 * @param thread_id     index of thread
 * @param frame_id      index of stack frame
 *
 * @return 1 if up-to-date, 0 if not, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_have_autovars(int thread_id,int frame_id);
/**
 * Get the details about a auto-watch variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param watch_id    index of variable in list of auto-watches
 * @param expr        (reference) expression to evaluate
 * @param value       (reference) value of variable
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_autovar(int thread_id,int frame_id,int watch_id,
                    _str &expr,_str &value, _str &raw_value);
/**
 * Get the details about an auto-watch variable or expanded auto-watch variable
 * 
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param watch_path  path to auto-watch variable in tree
 * @param name        (reference) name of local
 * @param class_name  (reference) name of class the member is in
 * @param signature   (reference) type of local variable
 * @param value       (reference) value of variable
 * @param flags       (reference) set to bitset of DEBUG_MODEL_FLAGS_*
 * 
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_autovar_info(int thread_id,int frame_id,_str watch_path,
                         _str &name, _str &class_name, _str &signature,
                         _str &value, int &flags, _str &raw_value);

/**
 * Collapse all the nodes under the given auto-watched variable.
 *
 * @param thread_id   index of thread
 * @param frame_id    index of stack frame
 * @param watch_path  path to member in list of auto-watch variables
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_collapse_auto(int thread_id,int frame_id,_str watch_path);

/**
 * Get the details about a breakpoint.
 *
 * @param breakpoint_id index of variable in list of breakpoints
 * @param count         (reference) number of times to skip breakpoint
 *                      -1 indicates that it is a one-time breakpoint
 * @param condition     (reference) expression for conditional breakpoint
 * @param thread_name   (reference) name of thread breakpoint is restricted to
 * @param class_name    (reference) name of class breakpoint is restricted to
 * @param method_name   (reference) name of method breakpoint is set in
 * @param file_name     (reference) name of file breakpoint is in
 * @param line_number   (reference) line number breakpoint occurs at
 * @param enabled       (reference) is the breakpoint enabled or disabled
 * @param address       (reference) hex address to search from breakpoint matching
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint(int breakpoint_id,
                       int &count,
                       _str &condition,
                       _str &thread_name,
                       _str &class_name,
                       _str &method_name,
                       _str &file_name,
                       int &line_number,
                       bool &enabled,
                       _str &address);
/**
 * Find the breakpoint at the given file and line number.
 *
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number breakpoint occurs at
 * @param enabled       (reference) is the breakpoint enabled or disabled
 * @param start_id      (optional) breakpoint ID to start searching at, default 0
 * @param address       (optional) hex address to search for breakpoint matching
 *
 * @return breakpoint ID > 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_find_breakpoint(_str file_name,int line_number,bool &enabled,
                        int start_id=0,_str address=null);
/**
 * Add a breakpoint.  The breakpoint is initially disabled at the
 * time that it is inserted.  You must call the package-specific
 * callback to enable the breakpoint.
 *
 * @param count         number of times to skip breakpoint
 *                      -1 indicates that it is a one-time breakpoint
 * @param condition     expression for conditional breakpoint
 * @param thread_name   name of thread breakpoint is restricted to
 * @param class_name    name of class breakpoint is restricted to
 * @param method_name   name of method breakpoint is set in
 * @param file_name     name of file breakpoint is in
 * @param line_number   line number breakpoint occurs at
 * @param address       (optional) hex instruction address to set breakpoint at
 * @param type          breakpoint type (line, method, watch)
 *                      see {@link dbg_get_breakpoint_type()}
 * @param flags         bitset of VSDEBUG_BREAKPOINT_FLAG_*
 *
 * @return breakpoint index &gt;0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_breakpoint(int count, _str condition,
                       _str thread_name, _str class_name, _str method_name,
                       _str file_name, int line_number, _str address='',
                       int type=VSDEBUG_BREAKPOINT_LINE, int flags=0);
/**
 * Remove the given breakpoint.  Note that the breakpoint must be
 * disabled first using the package-specific disable routine.
 * Otherwise an error is returned.
 *
 * @param breakpoint_id       Breakpoint to remove
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_remove_breakpoint(int breakpoint_id);

/**
 * Enable or disable the given breakpoint.  Note that this
 * function should be called only when outside of debugging mode.
 * Normally, you would use the packge-specific callback to
 * enable a breakpoint.
 *
 * @param breakpoint_id       Breakpoint to enable
 * @param enabled             True of false
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_breakpoint_enabled(int breakpoint_id,int enabled);

/**
 * Return the status (enabled or disabled) for the given breakpoint.
 *
 * @param breakpoint_id       Breakpoint to examine
 *
 * @return 1 for enabled, 0 for disabled, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_enabled(int breakpoint_id);
/**
 * Get the class and method scope of the specified breakpoint.
 *
 * @param breakpoint_id       Breakpoint to examine
 * @param class_name          Name of class that breakpoint is set in
 * @param method_name         Name of method that breakpoint is set in
 *
 * @return 1 for enabled, 0 for disabled, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_scope(int breakpoint_id,_str &class_name,_str &method_name);
/**
 * Modify the class name / method scope for a breakpoint.
 *
 * @param breakpoint_id       Breakpoint to enable
 * @param class_name          class that breakpoint is set in
 * @param method_name         name of function breakpoint is set in
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_breakpoint_scope(int breakpoint_id,
                             _str class_name, _str method_name);
/**
 * Get the file and line number for the specified breakpoint.
 *
 * @param breakpoint_id       Breakpoint to examine
 * @param file_name           Name of file breakpoint is in
 * @param line_number         Line that breakpoint is on
 *
 * @return 1 for enabled, 0 for disabled, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_location(int breakpoint_id,_str &file_name,int &line_number);
/**
 * Modify the file, line, and address location information for
 * a breakpoint.
 *
 * @param breakpoint_id       Breakpoint to enable
 * @param file_name           file breakpoint is set in
 * @param line_number         line number to set breakpoint at
 * @param address             breakpoint address
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_breakpoint_location(int breakpoint_id,
                                _str file_name, int line_number, _str address);
/**
 * Get the condition constraint for the specified breakpoint.
 *
 * @param breakpoint_id index of variable in list of breakpoints
 * @param condition     (reference) expression for conditional breakpoint
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_condition(int breakpoint_id,_str &condition);
/**
 * Get the count constraint for the specified breakpoint.
 *
 * @param breakpoint_id index of variable in list of breakpoints
 *
 * @return -1 for temporary breakpoint, <-1 on error, >=0 otherwise
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_count(int breakpoint_id);
/**
 * Get the type of a breakpoint (line, method, or watch)
 * <ul>
 *    <li>VSDEBUG_BREAKPOINT_LINE -- file/line oriented breakpoint
 *    <li>VSDEBUG_BREAKPOINT_METHOD -- class/method breakpoint
 *    <li>VSDEBUG_BREAKPOINT_ADDRESS -- address within a function
 *    <li>VSDEBUG_WATCHPOINT_READ -- read access on breakpoint condition
 *    <li>VSDEBUG_WATCHPOINT_WRITE -- write access on breakpoint condition
 *    <li>VSDEBUG_WATCHPOINT_ANY -- any access on breakpoint condition
 *    <li>VSDEBUG_WATCHPOINT_INSTANCE_READ -- read access on breakpoint condition
 *    <li>VSDEBUG_WATCHPOINT_INSTANCE_WRITE -- write access on breakpoint condition
 *    <li>VSDEBUG_WATCHPOINT_INSTANCE_ANY -- any access on breakpoint condition
 * </ul>
 *
 * @param breakpoint_id    index of variable in list of breakpoints
 * @param breakpoint_flags (reference) set to bitset of VSDEBUG_WATCHPOINT_FLAG_*
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_breakpoint_type(int breakpoint_id, int &breakpoint_flags);

/**
 * Add a exception.  The exception is initially disabled at the
 * time that it is inserted.  You must call the package-specific
 * callback to enable the exception.
 *
 * @param stop_when     THROWN, CAUGHT, UNCAUGHT
 * @param count         number of times to skip breakpoint
 *                      -1 indicates that it is a one-time breakpoint
 * @param condition     expression for conditional exception
 * @param class_name    name of exception to catch
 * @param thread_name   name of thread breakpoint is restricted to
 *
 * @return exception index &gt;0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_exception(int stop_when, int count,
                      _str condition,_str class_name,_str thread_name);
/**
 * Remove the given exception.  Note that the exception must be
 * disabled first using the package-specific disable routine.
 * Otherwise an error is returned.
 *
 * @param exception_id       Exception to remove
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_remove_exception(int exception_id);
/**
 * Enable or disable the given exception.  Note that this
 * function should be called only when outside of debugging mode.
 * Normally, you would use the packge-specific callback to
 * enable a exception.
 *
 * @param exception_id       Exception to remove
 * @param enabled             True of false
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_exception_enabled(int exception_id,int enabled);
/**
 * Return the status (enabled or disabled) for the given exception.
 *
 * @param exception_id       Exception to remove
 *
 * @return 1 for enabled, 0 for disabled, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_exception_enabled(int exception_id);
/**
 * Get the class and method scope of the specified exception.
 *
 * @param exception_id       Exception to examine
 * @param class_name          Name of class that exception is set in
 * @param method_name         Name of method that exception is set in
 *
 * @return 1 for enabled, 0 for disabled, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_exception_class(int exception_id,_str &class_name);
/**
 * Get the details about an exception.
 *
 * @param exception_id  index of variable in list of exceptions
 * @param stop_when     (reference) THROWN, CAUGHT, UNCAUGHT
 * @param count         (reference) number of times to skip breakpoint
 *                      -1 indicates that it is a one-time breakpoint
 * @param condition     (reference) expression for conditional exception
 * @param class_name    (reference) name of exception to catch
 * @param thread_name   (reference) name of thread breakpoint is restricted to
 * @param enabled       (reference) is the exception enabled or disabled
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_exception(int exception_id,
                      int &stop_when, int &count,
                      _str &condition, _str &class_name,
                      _str &thread_name, bool &enabled);
/**
 * Get the condition constraint for the specified exception.
 *
 * @param exception_id  index of variable in list of exceptions
 * @param condition     (reference) expression for conditional breakpoint
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_exception_condition(int exception_id,_str &condition);
/**
 * Get the count constraint for the specified exception.
 *
 * @param exception_id index of variable in list of exceptions
 *
 * @return -1 for temporary breakpoint, <-1 on error, >=0 otherwise
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_exception_count(int exception_id);
/**
 * Find the exception with the given class name
 *
 * @param class_name    name class corresponding to exception
 * @param enabled       (reference) is the exception enabled or disabled
 * @param start_id      (optional) exception ID to start searching at, default 0
 *
 * @return exception ID > 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_find_exception(_str class_name, int &enabled,int start_id);

/**
 * Add a watched variable.
 *
 * @param tab_number    which tab to display this watch on
 * @param expr          expression to evaluate
 * @param context       context to evaluate watch in
 * @param base          base to display value in
 *
 * @return watch ID index &gt;0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_watch(int tab_number,_str expr,_str context_name,int base);
/**
 * Modify a watch expression.
 *
 * @param watch_id      watch to modify
 * @param expr          expression to evaluate
 * @param context_name  context to evaluate expression in
 * @param base          base to display value in
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_set_watch(int watch_id,_str expr,_str context_name,int base);
/**
 * Add a auto-watched variable.
 *
 * @param expr          expression to evaluate
 * @param thread_id     index of thread
 * @param frame_id      index of stack frame
 *
 * @return watch ID index &gt;0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_add_autovar(int thread_id,int frame_id,_str expr);
/**
 * Remove the given watch variable/expression.
 *
 * @param watch_id       Watch to remove
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_remove_watch(int watch_id);
/**
 * Remove all the watches, both persistent and dynamic data.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_watches();
/**
 * Remove all the auto watches.
 *
 * @param thread_id     index of thread
 * @param frame_id      index of stack frame
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_autos(int thread_id,int frame_id);
/**
 * Remove all the source paths.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_sourcedirs();
/**
 * Remove all the runtime exclude exprs.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_runtimes();
/**
 * Remove all the breakpoints.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_breakpoints();

/**
 * Remove all the exceptions.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_exceptions();
/**
 * Indicate that the classes model is out of date.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_classes();

/**
 * Indicate that the registers model is out of date
 * 
 * @param thread_id    thread ID to clear registers for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_registers(int thread_id=0);

/**
 * Indicate that the current memory dump region is out of date
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_memory();

/**
 * Indicate that the list of threads and thread gruops are out of date
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_threads();

/**
 * Indicate that the stack frame is out of date
 *
 * @param thread_id     specific thread ID to invalidate
 *                      if 0, invalidate stack for all threads.
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_stack(int thread_id=0);

/**
 * Indicate that the variables everywhere are out of date
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_variables();
/**
 * Indicate that all the watch variables are out of date. 
 * This is necessary when switching tabs in the watch window. 
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_watch_variables();
/**
 * Clear the disassembly lines for the given file name.
 * If 'file_name' is NULL, clear the disassembly for all files.
 * 
 * @param file_name     source file to remove disassembly for
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Debugger_Functions
 */
extern int dbg_clear_disassembly(_str file_name=null);

/**
 * Gets a list of valid bases
 * 
 * @param base_list array to store list of bases in
 * 
 * @categories Debugger_Functions
 */
extern void dbg_get_supported_format_list(int (&base_list)[]);

/**
 * Gets the current global base
 * 
 * @return the current global base
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_global_format();

/**
 * Sets the current global base
 * 
 * @param new_base base to set as global base
 * 
 * @categories Debugger_Functions
 */
extern void dbg_set_global_format(int new_base);

/**
 * Sets the base for a variable
 * 
 * @param var_name name of variable to set base for
 * @param new_base new base for a variable
 * 
 * @categories Debugger_Functions
 */
extern void dbg_set_var_format(_str var_name,int new_base);

/**
 * Gets the base for a variable
 * @param var_name name of variable to get base for
 * 
 * @return base of variable specified by <B>var_name</B>
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_var_format(_str var_name);

/**
 * Gets the name of base specified by <B>base</B>
 * @return name of base specified by <B>base</B>
 * 
 * @categories Debugger_Functions
 */
extern _str dbg_get_format_name(int base);

/**
 * Gets the number of non-watch variables formatted (formatted watch variables 
 * override these settings and are stored separately)
 * 
 * @return the number of non-watch variables formatted
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_num_formatted_vars();

/**
 * 
 * @param formatted_var_list variable that the list is put in
 * @return 0 if succesful
 * 
 * @categories Debugger_Functions
 */
extern int dbg_get_formatted_var(int index,_str &formatted_var);

/**
 * @return 
 * Returns 'true' if the given number base option applies to the given data type. 
 * 
 * @param iBase           number base formatting option
 * @param pszFormatType   data type 
 *                        <ul> 
 *                        <li><b>integer, number</b> -- integer types</li>
 *                        <li><b>float, double</b> -- floating point types</li>
 *                        <li><b>string</b> -- string types</li>
 *                        <li><b>char</b> -- character types</li>
 *                        </ul>
 * 
 * @categories Debugger_Functions
 */
extern bool dbg_get_format_is_for_type(int iBase, _str pszFormatType);

/**
 *
 * @param filename 
 * 
 * @categories Debugger_Functions
 */
extern int dbg_windbg_write_dumpfile(_str filename);

/**
 *
 * @param modules 
 * 
 * @categories Debugger_Functions
 */
extern int dbg_windbg_get_modules(_str (&modulelist)[]);

extern int dbg_windbg_get_symbols_path(_str &path);
extern int dbg_windbg_set_symbols_path(_str path);
extern int dbg_windbg_get_image_path(_str &path);
extern int dbg_windbg_set_image_path(_str path);

