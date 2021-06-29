#!/usr/bin/ruby
# Copyright (c) 2005-2006 ActiveState Software Inc.
#
# See the LICENSE file for full details on this software's license.
# 
# Authors:
#    Eric Promislow <EricP@ActiveState.com>

module Debugger
module DBGP
module Constants

# Constants

# Error Codes

DBP_E_NoError = 0;
DBP_E_ParseError = 1;
DBP_E_DuplicateArguments = 2;
DBP_E_InvalidOption = 3;
DBP_E_CommandUnimplemented = 4;
DBP_E_CommandNotAvailable = 5;

#todo: add this to protocol
DBP_E_UnrecognizedCommand = 6;

DBP_E_CantOpenSource = 100;

DBP_E_BreakpointNotSet = 200;
DBP_E_BreakpointTypeNotSupported = 201;
DBP_E_Unbreakable_InvalidCodeLine = 202;
DBP_E_Unbreakable_EmptyCodeLine = 203;
DBP_E_BreakpointStateInvalid = 204;
DBP_E_NoSuchBreakpoint = 205;
DBP_E_PropertyEvalError = 206;
DBP_E_CantSetProperty = 207;

DBP_E_CantGetProperty = 300;
DBP_E_StackDepthInvalid = 301;
DBP_E_ContextInvalid = 302;

DBP_E_EncodingNotSupported = 900;
DBP_E_InternalException = 998;
DBP_E_UnknownError = 999;

NV_NAME = 0;
NV_VALUE = 1;
NV_NEED_MAIN_LEVEL_EVAL = 2;
NV_UNSET_FLAG = 3;

BKPT_DISABLE = 1;
BKPT_ENABLE = 2;
BKPT_TEMPORARY = 3;

# Indices into the breakpoint Table

BKPTBL_FILEURI = 0;
BKPTBL_LINENO = 1;
BKPTBL_STATE = 2;
BKPTBL_TYPE = 3;
BKPTBL_FUNCTION_NAME = 4;
BKPTBL_CONDITION = 5;
BKPTBL_EXCEPTION = 6;
BKPTBL_HIT_INFO = 7;

BKPT_FUNCTION_CALL = 0
BKPT_FUNCTION_RETURN = 1

HIT_TBL_COUNT = 0; # No. Times we've hit this bpt
HIT_TBL_VALUE = 1; # Target hit value
HIT_TBL_EVAL_FUNC = 2; # Function to call(VALUE, COUNT)
HIT_TBL_COND_STRING = 3; # Condition string

IB_STATE_NONE = 0;
IB_STATE_START = 1;
IB_STATE_PENDING = 2;

STOP_REASON_STARTING = 0;
STOP_REASON_STOPPING = 1;
STOP_REASON_STOPPED = 2;
STOP_REASON_RUNNING = 3;
STOP_REASON_BREAK = 4;
STOP_REASON_INTERACT = 5;

# Reasons for breaking
SINGLE_DONT_STOP = 0
SINGLE_STEP_IN = 1
SINGLE_STEP_OVER = 2

#Frame indexing
FRAME_IDX_BINDING = 0
FRAME_IDX_FILENAME = 1
FRAME_IDX_LINENO = 2
FRAME_IDX_ID = 3
FRAME_IDX_SINGLE = 4

  #Event codes
  RB_EVENT_LINE = 1
  RB_EVENT_CALL = 2
  RB_EVENT_C_CALL = 3
  RB_EVENT_C_RETURN = 4
  RB_EVENT_CLASS = 5
  RB_EVENT_RETURN = 6
  RB_EVENT_END = 7
  RB_EVENT_RAISE = 8
  RB_EVENT_UNKNOWN = 9

  # Property Enums
  LocalVars = 0
  GlobalVars = 1
  PunctuationVariables = 2
  InstanceVars = 3
  BuiltinGlobals = 4

end
end
end
