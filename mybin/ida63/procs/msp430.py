# ----------------------------------------------------------------------
# Texas Instruments MSP430 processor module
# Copyright (c) 2010-2011 Hex-Rays
#
# This module demonstrates:
#  - instruction decoding and printing
#  - simplification of decoded instructions
#  - creation of code and data cross-references
#  - auto-creation of data items from cross-references
#  - tracing of the stack pointer changes
#  - creation of the stack variables
#  - handling of switch constructs
#
# Please send fixes or improvements to support@hex-rays.com

import sys
import idaapi
import copy
from idaapi import *

# extract bitfield occupying bits high..low from val (inclusive, start from 0)
def BITS(val, high, low):
  return (val>>low)&((1<<(high-low+1))-1)

# extract one bit
def BIT(val, bit):
  return (val>>bit) & 1

# sign extend b low bits in x
# from "Bit Twiddling Hacks"
def SIGNEXT(x, b):
  m = 1 << (b - 1)
  x = x & ((1 << b) - 1)
  return (x ^ m) - m

# values for specval field for o_phrase operands
FL_INDIRECT = 1  # indirect: @Rn
FL_AUTOINC  = 2  # auto-increment: @Rn+

# values for specval field for o_mem operands
FL_ABSOLUTE = 1  # absolute: &addr
FL_SYMBOLIC = 2  # symbolic: addr

# values for cmd.auxpref
AUX_SIZEMASK = 0x0F
AUX_NOSUF   = 0x00  # no suffix (e.g. SWPB)
AUX_WORD    = 0x01  # word transfer, .W suffix
AUX_BYTE    = 0x02  # byte transfer, .B suffix
AUX_A       = 0x03  # 20-bit transfer, .A suffix
AUX_AX      = 0x04  # 20-bit immediate/address, no suffix
AUX_REPIMM  = 0x10  # immediate repeat count present (in cmd.segpref)
AUX_REPREG  = 0x20  # register repeat count (reg no in in cmd.segpref)
AUX_ZC      = 0x40  # zero carry flag is set

# addressing mode field in the opcode
AM_REGISTER = 0 # Rn
AM_INDEXED  = 1 # X(Rn), also includes symbolic and absolute
AM_INDIRECT = 2 # @Rn
AM_AUTOINC  = 3 # @Rn+, also includes immediate (#N = @PC+)
# extra formats
AM_IMM20    = 100 # Rn is imm19:16, imm15:0 follows
AM_ABS20    = 101 # Rn is &abs19:16, &abs15:0 follows
AM_SYM20    = 102 # as IMM20, plus PC value

# operand data length value
#                 A/L B/W
DLEN_WORD   = 0 #  1   0   16-bit word
DLEN_BYTE   = 1 #  1   1   8-bit byte
DLEN_AWORD  = 2 #  0   1   20-bit address-word
DLEN_LONG   = 3 #  0   0   Reserved

# check if operand is immediate value val
def is_imm(op, val):
    if op.type == o_imm:
        # workaround for difference between Python and native numbers
        op2 = op_t()
        op2.value = val
        return op.value == op2.value
    return False

# are operands equal?
def same_op(op1, op2):
    return op1.type  == op2.type  and \
           op1.reg   == op2.reg   and \
           op1.value == op2.value and \
           op1.addr  == op2.addr  and \
           op1.flags == op2.flags and \
           op1.specval == op2.specval and \
           op1.dtyp == op2.dtyp

# is operand auto-increment register reg?
def is_autoinc(op, reg):
    return op.type == o_phrase and op.reg == reg and op.specval == FL_AUTOINC

# is sp delta fixed by the user?
def is_fixed_spd(ea):
    return (get_aflags(ea) & AFL_FIXEDSPD) != 0

# ----------------------------------------------------------------------
class msp430_processor_t(idaapi.processor_t):
    """
    Processor module classes must derive from idaapi.processor_t
    """

    # IDP id ( Numbers above 0x8000 are reserved for the third-party modules)
    id = idaapi.PLFM_MSP430

    # Processor features
    flag = PR_SEGS | PRN_HEX | PR_RNAMESOK | PR_NO_SEGMOVE | PR_WORD_INS | PR_USE32

    # Number of bits in a byte for code segments (usually 8)
    # IDA supports values up to 32 bits
    cnbits = 8

    # Number of bits in a byte for non-code segments (usually 8)
    # IDA supports values up to 32 bits
    dnbits = 8

    # short processor names
    # Each name should be shorter than 9 characters
    psnames = ['msp430']

    # long processor names
    # No restriction on name lengthes.
    plnames = ['Texas Instruments MSP430']

    # size of a segment register in bytes
    segreg_size = 0

    # Array of typical code start sequences (optional)
    codestart = ['\x0B\x12']  # 120B: push R11

    # Array of 'return' instruction opcodes (optional)
    # retcodes = ['\x30\x41']   # 4130: ret (mov.w @SP+, PC)

    # Array of instructions
    instruc = [
        {'name': '',  'feature': 0},                                # placeholder for "not an instruction"

        # two-operand instructions
        {'name': 'mov',  'feature': CF_USE1 | CF_CHG2,             'cmt': "Move source to destination"},
        {'name': 'add',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Add source to destination"},
        {'name': 'addc', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Add source and carry to destination"},
        {'name': 'subc', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Subtract source with carry from destination"},
        {'name': 'sub',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Subtract source from destination"},
        {'name': 'cmp',  'feature': CF_USE1 | CF_USE2,             'cmt': "Compare source and destination"},
        {'name': 'dadd', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Add source decimally to destination"},
        {'name': 'bit',  'feature': CF_USE1 | CF_USE2,             'cmt': "Test bits set in source in destination"},
        {'name': 'bic',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Clear bits set in source in destination"},
        {'name': 'bis',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Set bits set in source in destination"},
        {'name': 'xor',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Exclusive OR source with destination"},
        {'name': 'and',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,   'cmt': "Binary AND source and destination"},
        
        # MSP430X instructions
        {'name': 'movx',  'feature': CF_USE1 | CF_CHG2,            'cmt': "Move source to destination"},
        {'name': 'addx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Add source to destination"},
        {'name': 'addcx', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Add source and carry to destination"},
        {'name': 'subcx', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Subtract source with carry from destination"},
        {'name': 'subx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Subtract source from destination"},
        {'name': 'cmpx',  'feature': CF_USE1 | CF_USE2,            'cmt': "Compare source and destination"},
        {'name': 'daddx', 'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Add source decimally to destination"},
        {'name': 'bitx',  'feature': CF_USE1 | CF_USE2,            'cmt': "Test bits set in source in destination"},
        {'name': 'bicx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Clear bits set in source in destination"},
        {'name': 'bisx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Set bits set in source in destination"},
        {'name': 'xorx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Exclusive OR source with destination"},
        {'name': 'andx',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Binary AND source and destination"},
        {'name': 'rrcm',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Rotate right through C"},
        {'name': 'rram',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Rotate right arithmetically"},
        {'name': 'rlam',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Rotate left arithmetically"},
        {'name': 'rrum',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Rotate right unsigned"},
        {'name': 'pushm', 'feature': CF_USE1 | CF_USE2,            'cmt': "Push registers onto stack"},
        {'name': 'popm',  'feature': CF_USE1 | CF_CHG2,            'cmt': "Pop registers from the stack"},
        
        # MSP430X address instructions
        {'name': 'mova',  'feature': CF_USE1 | CF_CHG2,            'cmt': "Move source to destination"},
        {'name': 'cmpa',  'feature': CF_USE1 | CF_USE2,            'cmt': "Compare source and destination"},
        {'name': 'adda',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Add source to destination"},
        {'name': 'suba',  'feature': CF_USE1 | CF_USE2 | CF_CHG2,  'cmt': "Subtract source from destination"},

        # one-operand instructions
        {'name': 'rrc',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate right through C"},
        {'name': 'swpb', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Swap bytes"},
        {'name': 'rra',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate right arithmetically"},
        {'name': 'sxt',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Extend sign (8 bits to 16)"},
        {'name': 'push', 'feature': CF_USE1          ,   'cmt': "Push onto stack"},
        {'name': 'call', 'feature': CF_USE1          ,   'cmt': "Call subroutine"},
        {'name': 'reti', 'feature': CF_STOP          ,   'cmt': "Return from interrupt"},

        # MSP430X instructions
        {'name': 'rrcx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate right through carry"},
        {'name': 'swpbx','feature': CF_USE1 | CF_CHG1,   'cmt': "Exchange low byte with high byte"},
        {'name': 'rrax', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate right arithmetically"},
        {'name': 'sxtx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Extend sign of lower byte"},
        {'name': 'pushx','feature': CF_USE1          ,   'cmt': "Push onto stack"},
        {'name': 'calla','feature': CF_USE1          ,   'cmt': "Call subroutine (20-bit)"},
        {'name': 'rrux', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate right unsigned"},

        # jumps
        {'name': 'jnz',  'feature': CF_USE1          ,   'cmt': "Jump if not zero/not equal"},
        {'name': 'jz',   'feature': CF_USE1          ,   'cmt': "Jump if zero/equal"},
        {'name': 'jnc',  'feature': CF_USE1          ,   'cmt': "Jump if no carry/lower (unsigned)"},
        {'name': 'jc',   'feature': CF_USE1          ,   'cmt': "Jump if carry/higher or same (unsigned)"},
        {'name': 'jn',   'feature': CF_USE1          ,   'cmt': "Jump if negative"},
        {'name': 'jge',  'feature': CF_USE1          ,   'cmt': "Jump if greater or equal (signed)"},
        {'name': 'jl',   'feature': CF_USE1          ,   'cmt': "Jump if less (signed)"},
        {'name': 'jmp',  'feature': CF_USE1 | CF_STOP,   'cmt': "Jump unconditionally"},

        # emulated instructions
        {'name': 'adc',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Add carry to destination"},
        {'name': 'br',   'feature': CF_USE1 | CF_STOP,   'cmt': "Branch to destination"},
        {'name': 'clr',  'feature': CF_CHG1          ,   'cmt': "Clear destination"},
        {'name': 'clrc', 'feature': 0                ,   'cmt': "Clear carry bit"},
        {'name': 'clrn', 'feature': 0                ,   'cmt': "Clear negative bit"},
        {'name': 'clrz', 'feature': 0                ,   'cmt': "Clear zero bit"},
        {'name': 'dadc', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Add carry decimally to destination"},
        {'name': 'dec',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Decrement destination"},
        {'name': 'decd', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Double-decrement destination"},
        {'name': 'dint', 'feature': 0                ,   'cmt': "Disable general interrupts"},
        {'name': 'eint', 'feature': 0                ,   'cmt': "Enable general interrupts"},
        {'name': 'inc',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Increment destination"},
        {'name': 'incd', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Double-increment destination"},
        {'name': 'inv',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Invert destination"},
        {'name': 'nop',  'feature': 0                ,   'cmt': "No operation"},
        {'name': 'pop',  'feature': CF_CHG1          ,   'cmt': "Pop from the stack"},
        {'name': 'ret',  'feature': CF_STOP          ,   'cmt': "Return from subroutine"},
        {'name': 'rla',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate left arithmetically"},
        {'name': 'rlc',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate left through carry"},
        {'name': 'sbc',  'feature': CF_USE1 | CF_CHG1,   'cmt': "Substract borrow (=NOT carry) from destination"},
        {'name': 'setc', 'feature': 0                ,   'cmt': "Set carry bit"},
        {'name': 'setn', 'feature': 0                ,   'cmt': "Set negative bit"},
        {'name': 'setz', 'feature': 0                ,   'cmt': "Set zero bit"},
        {'name': 'tst',  'feature': CF_USE1          ,   'cmt': "Test destination"},
        # MSP430X instructions
        {'name': 'adcx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Add carry to destination"},
        {'name': 'bra',  'feature': CF_USE1 | CF_STOP,   'cmt': "Branch indirect to destination"},
        {'name': 'reta', 'feature': CF_STOP          ,   'cmt': "Return from subroutine"},
        {'name': 'popa', 'feature': CF_CHG1          ,   'cmt': "Pop from the stack"},
        {'name': 'clra', 'feature': CF_CHG1          ,   'cmt': "Clear destination"},
        {'name': 'clrx', 'feature': CF_CHG1          ,   'cmt': "Clear destination"},
        {'name': 'dadcx','feature': CF_USE1 | CF_CHG1,   'cmt': "Add carry decimally to destination"},
        {'name': 'decx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Decrement destination"},
        {'name': 'decda','feature': CF_USE1 | CF_CHG1,   'cmt': "Double-decrement destination"},
        {'name': 'decdx','feature': CF_USE1 | CF_CHG1,   'cmt': "Double-decrement destination"},
        {'name': 'incx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Increment destination"},
        {'name': 'incda','feature': CF_USE1 | CF_CHG1,   'cmt': "Double-increment destination"},
        {'name': 'incdx','feature': CF_USE1 | CF_CHG1,   'cmt': "Double-increment destination"},
        {'name': 'invx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Invert destination"},
        {'name': 'rlax', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate left arithmetically"},
        {'name': 'rlcx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Rotate left through carry"},
        {'name': 'sbcx', 'feature': CF_USE1 | CF_CHG1,   'cmt': "Substract borrow (=NOT carry) from destination"},
        {'name': 'tsta', 'feature': CF_USE1          ,   'cmt': "Test destination"},
        {'name': 'tstx', 'feature': CF_USE1          ,   'cmt': "Test destination"},
        {'name': 'popx', 'feature': CF_CHG1          ,   'cmt': "Pop from the stack"},
    ]

    # icode of the first instruction
    instruc_start = 0

    # icode of the last instruction + 1
    instruc_end = len(instruc) + 1

    # Size of long double (tbyte) for this processor (meaningful only if ash.a_tbyte != NULL) (optional)
    # tbyte_size = 0

    #
    # Number of digits in floating numbers after the decimal point.
    # If an element of this array equals 0, then the corresponding
    # floating point data is not used for the processor.
    # This array is used to align numbers in the output.
    #      real_width[0] - number of digits for short floats (only PDP-11 has them)
    #      real_width[1] - number of digits for "float"
    #      real_width[2] - number of digits for "double"
    #      real_width[3] - number of digits for "long double"
    # Example: IBM PC module has { 0,7,15,19 }
    #
    # (optional)
    real_width = (0, 7, 0, 0)


    # only one assembler is supported
    assembler = {
        # flag
        'flag' : ASH_HEXF0 | ASD_DECF0 | ASO_OCTF5 | ASB_BINF0 | AS_N2CHR,

        # user defined flags (local only for IDP) (optional)
        'uflag' : 0,

        # Assembler name (displayed in menus)
        'name': "Generic MSP430 assembler",

        # array of automatically generated header lines they appear at the start of disassembled text (optional)
        'header': [".msp430"],

        # array of unsupported instructions (array of cmd.itype) (optional)
        #'badworks': [],

        # org directive
        'origin': ".org",

        # end directive
        'end': ".end",

        # comment string (see also cmnt2)
        'cmnt': ";",

        # ASCII string delimiter
        'ascsep': "\"",

        # ASCII char constant delimiter
        'accsep': "'",

        # ASCII special chars (they can't appear in character and ascii constants)
        'esccodes': "\"'",

        #
        #      Data representation (db,dw,...):
        #
        # ASCII string directive
        'a_ascii': ".char",

        # byte directive
        'a_byte': ".byte",

        # word directive
        'a_word': ".short",

        # remove if not allowed
        'a_dword': ".long",

        # remove if not allowed
        # 'a_qword': "dq",

        # float;  4bytes; remove if not allowed
        'a_float': ".float",

        # uninitialized data directive (should include '%s' for the size of data)
        'a_bss': ".space %s",

        # 'equ' Used if AS_UNEQU is set (optional)
        'a_equ': ".equ",

        # 'seg ' prefix (example: push seg seg001)
        'a_seg': "seg",

        # current IP (instruction pointer) symbol in assembler
        'a_curip': "$",

        # "public" name keyword. NULL-gen default, ""-do not generate
        'a_public': ".def",

        # "weak"   name keyword. NULL-gen default, ""-do not generate
        'a_weak': "",

        # "extrn"  name keyword
        'a_extrn': ".ref",

        # "comm" (communal variable)
        'a_comdef': "",

        # "align" keyword
        'a_align': ".align",

        # Left and right braces used in complex expressions
        'lbrace': "(",
        'rbrace': ")",

        # %  mod     assembler time operation
        'a_mod': "%",

        # &  bit and assembler time operation
        'a_band': "&",

        # |  bit or  assembler time operation
        'a_bor': "|",

        # ^  bit xor assembler time operation
        'a_xor': "^",

        # ~  bit not assembler time operation
        'a_bnot': "~",

        # << shift left assembler time operation
        'a_shl': "<<",

        # >> shift right assembler time operation
        'a_shr': ">>",

        # size of type (format string) (optional)
        'a_sizeof_fmt': "size %s",

        'flag2': 0,

        # the include directive (format string) (optional)
        'a_include_fmt': '.include "%s"',
    } # Assembler


    # ----------------------------------------------------------------------
    # The following callbacks are optional
    #

    #def notify_newprc(self, nproc):
    #    """
    #    Before changing proccesor type
    #    nproc - processor number in the array of processor names
    #    return 1-ok,0-prohibit
    #    """
    #    return 1

    #def notify_assemble(self, ea, cs, ip, use32, line):
    #    """
    #    Assemble an instruction
    #     (make sure that PR_ASSEMBLE flag is set in the processor flags)
    #     (display a warning if an error occurs)
    #     args:
    #       ea -  linear address of instruction
    #       cs -  cs of instruction
    #       ip -  ip of instruction
    #       use32 - is 32bit segment?
    #       line - line to assemble
    #    returns the opcode string
    #    """
    #    pass

    def get_frame_retsize(self, func_ea):
        """
        Get size of function return address in bytes
        If this function is absent, the kernel will assume
             4 bytes for 32-bit function
             2 bytes otherwise
        """
        return 2

    def notify_get_autocmt(self):
        """
        Get instruction comment. 'cmd' describes the instruction in question
        @return: None or the comment string
        """
        if 'cmt' in self.instruc[self.cmd.itype]:
          return self.instruc[self.cmd.itype]['cmt']

    # ----------------------------------------------------------------------
    def notify_is_sane_insn(self, no_crefs):
        """
        is the instruction sane for the current file type?
        args: no_crefs
        1: the instruction has no code refs to it.
           ida just tries to convert unexplored bytes
           to an instruction (but there is no other
           reason to convert them into an instruction)
        0: the instruction is created because
           of some coderef, user request or another
           weighty reason.
        The instruction is in 'cmd'
        returns: 1-ok, <=0-no, the instruction isn't
        likely to appear in the program
        """
        w = Word(self.cmd.ea)
        if w == 0 or w == 0xFFFF:
          return 0
        return 1

    # ----------------------------------------------------------------------
    def is_movpc(self):
        # mov xxx, PC
        return self.cmd.itype == self.itype_mov and self.cmd.Op2.is_reg(self.ireg_PC) and self.cmd.auxpref == AUX_WORD

    # ----------------------------------------------------------------------
    def changes_pc(self):
        Feature = self.cmd.get_canon_feature()
        if (Feature & CF_CHG2) and self.cmd.Op2.is_reg(self.ireg_PC):
          return True
        if (Feature & CF_CHG1) and self.cmd.Op1.is_reg(self.ireg_PC):
          return True
        return False

    # ----------------------------------------------------------------------
    def handle_operand(self, op, isRead):
        uFlag     = self.get_uFlag()
        is_offs   = isOff(uFlag, op.n)
        dref_flag = dr_R if isRead else dr_W
        def_arg   = isDefArg(uFlag, op.n)
        optype    = op.type

        itype = self.cmd.itype
        # create code xrefs
        if optype == o_imm:
            makeoff = False
            if itype in [self.itype_call, self.itype_calla]:
                # call #func
                ua_add_cref(op.offb, op.value, fl_CN)
                makeoff = True
            elif self.is_movpc() or self.cmd.itype in [self.itype_br, self.itype_bra]:
                # mov #addr, PC
                ua_add_cref(op.offb, op.value, fl_JN)
                makeoff = True
            if makeoff and not def_arg:
                set_offset(self.cmd.ea, op.n, self.cmd.cs)
                is_offs = True
            if is_offs:
                ua_add_off_drefs(op, dr_O)
        # create data xrefs
        elif optype == o_displ:
            # delta(reg)
            if is_offs:
                ua_add_off_drefs(op, dref_flag)
            elif may_create_stkvars() and not def_arg and op.reg == self.ireg_SP:
                # var_x(SP)
                pfn = get_func(self.cmd.ea)
                if pfn and ua_stkvar2(op, op.addr, STKVAR_VALID_SIZE):
                    op_stkvar(self.cmd.ea, op.n)
        elif optype == o_mem:
            ua_dodata2(op.offb, op.addr, op.dtyp)
            ua_add_dref(op.offb, op.addr, dref_flag)
        elif optype == o_near:
            ua_add_cref(op.offb, op.addr, fl_JN)

    # ----------------------------------------------------------------------
    def add_stkpnt(self, pfn, v):
        if pfn:
            end = self.cmd.ea + self.cmd.size
            if not is_fixed_spd(end):
                add_auto_stkpnt2(pfn, end, v)

    # ----------------------------------------------------------------------
    def trace_sp(self):
        """
        Trace the value of the SP and create an SP change point if the current
        instruction modifies the SP.
        """
        pfn = get_func(self.cmd.ea)
        if not pfn:
            return
        spofs = 0
        if self.cmd.itype in [self.itype_add, self.itype_addx, self.itype_adda, self.itype_addc, self.itype_addcx,
           self.itype_sub, self.itype_subx, self.itype_suba, self.itype_subc, self.itype_subcx] and \
           self.cmd.Op2.is_reg(self.ireg_SP) and self.cmd.auxpref in [AUX_WORD, AUX_A, AUX_AX] and \
           self.cmd.Op1.type == o_imm:
            # add.w  #xxx, SP
            # subc.w #xxx, SP
            if self.cmd.auxpref == AUX_WORD:
              spofs = SIGNEXT(self.cmd.Op1.value, 16)
            else:
              spofs = SIGNEXT(self.cmd.Op1.value, 20)
            if self.cmd.itype in [self.itype_sub, self.itype_subc, self.itype_subx, self.itype_subcx]:
                spofs = -spofs
        elif self.cmd.itype in [self.itype_incd, self.itype_decd, self.itype_incdx,
             self.itype_decdx, self.itype_incda, self.itype_decda] and \
             self.cmd.Op1.is_reg(self.ireg_SP) and self.cmd.auxpref in [AUX_WORD, AUX_A, AUX_AX]:
              spofs = 2 if self.cmd.itype in [self.itype_incd, self.itype_incdx] else -2
              self.add_stkpnt(pfn, spofs)
        elif self.cmd.itype == self.itype_push:
            spofs = -2
        elif self.cmd.itype in [self.itype_popm, self.itype_pushm, self.itype_popx, self.itype_pushx]:
            # popm.a #n, reg -> +n*4
            # popm.w #n, reg -> +n*2
            # popx.a reg     -> +4
            # popx.w reg     -> +2
            if self.cmd.itype in [self.itype_popm, self.itype_pushm]:
              count = self.cmd.Op1.value
            else:
              count = 1
            spofs = 1 if self.cmd.itype == self.itype_popm else -1
            if self.cmd.auxpref == AUX_A:
              spofs *= count * 4
            else:
              spofs *= count * 2              
        elif self.cmd.itype == self.itype_pop or is_autoinc(self.cmd.Op1, self.ireg_SP):
            # pop R7 or mov.w @SP+, R7
            if self.cmd.auxpref in [AUX_A, AUX_AX]:
              spofs = 4
            else:
              spofs = 2

        if spofs != 0:
          self.add_stkpnt(pfn, spofs)

    # ----------------------------------------------------------------------
    def check_switch(self):
        # detect switches and set switch info
        #
        #       cmp.w   #nn, Rx
        #       jc      default
        #       [mov.w   Rx, Ry]
        #       rla.w   Ry, Ry
        #       br      jtbl(Ry)
        # jtbl  .short case0, .short case1
        if get_switch_info_ex(self.cmd.ea):
            return
        ok = False
        si = switch_info_ex_t()
        saved_cmd = self.cmd.copy()

        # mov.w   jtbl(Ry), PC
        if (self.is_movpc() or self.cmd.itype in [self.itype_br, self.itype_bra]) and self.cmd.Op1.type == o_displ:
            si.jumps = self.cmd.Op1.addr # jump table address
            Ry = self.cmd.Op1.reg
            ok = True
            # add.w   Ry, Ry  | rla.w Ry
            if decode_prev_insn(self.cmd.ea) != BADADDR and self.cmd.auxpref == AUX_WORD:
               ok = self.cmd.itype == self.itype_add and self.cmd.Op1.is_reg(Ry) and self.cmd.Op2.is_reg(Ry) or \
                    self.cmd.itype == self.itype_rla and self.cmd.Op1.is_reg(Ry)
            else:
                ok = False
            if ok and decode_prev_insn(self.cmd.ea) != BADADDR:
               # mov.w   Rx, Ry
               if self.cmd.itype == self.itype_mov and \
                  self.cmd.Op2.is_reg(Ry) and \
                  cmd.Op1.type == o_reg and \
                  self.cmd.auxpref == AUX_WORD:
                   Rx = cmd.Op1.reg
                   ok = decode_prev_insn(self.cmd.ea) != BADADDR
               else:
                   Rx = Ry
            else:
                ok = False

            # jc default
            if ok and self.cmd.itype == self.itype_jc:
                si.defjump = self.cmd.Op1.addr
            else:
                ok = False

            # cmp.w   #nn, Rx
            if ok and decode_prev_insn(self.cmd.ea) == BADADDR or \
               self.cmd.itype != self.itype_cmp or \
               self.cmd.Op1.type != o_imm or \
               not self.cmd.Op2.is_reg(Rx) or \
               self.cmd.auxpref != AUX_WORD:
                ok = False
            else:
                si.flags |= SWI_DEFAULT
                si.ncases = cmd.Op1.value
                si.lowcase = 0
                si.startea = self.cmd.ea
                si.set_expr(Rx, dt_word)

        self.cmd.assign(saved_cmd)
        if ok:
            # make offset to the jump table
            set_offset(self.cmd.ea, 0, self.cmd.cs)
            set_switch_info_ex(self.cmd.ea, si)
            create_switch_table(self.cmd.ea, si)

    # ----------------------------------------------------------------------
    # The following callbacks are mandatory
    #
    def emu(self):
        """
        Emulate instruction, create cross-references, plan to analyze
        subsequent instructions, modify flags etc. Upon entrance to this function
        all information about the instruction is in 'cmd' structure.
        If zero is returned, the kernel will delete the instruction.
        """
        aux = self.get_auxpref()
        Feature = self.cmd.get_canon_feature()

        if Feature & CF_USE1:
            self.handle_operand(self.cmd.Op1, 1)
        if Feature & CF_CHG1:
            self.handle_operand(self.cmd.Op1, 0)
        if Feature & CF_USE2:
            self.handle_operand(self.cmd.Op2, 1)
        if Feature & CF_CHG2:
            self.handle_operand(self.cmd.Op2, 0)
        if Feature & CF_JUMP:
            QueueSet(Q_jumps, self.cmd.ea)

        # is it an unconditional jump?
        uncond_jmp = self.cmd.itype in [self.itype_jmp, self.itype_br, self.itype_bra] or self.changes_pc()

        # add flow
        flow = (Feature & CF_STOP == 0) and not uncond_jmp
        if flow:
            ua_add_cref(0, self.cmd.ea + self.cmd.size, fl_F)
        else:
            self.check_switch()

        # trace the stack pointer if:
        #   - it is the second analysis pass
        #   - the stack pointer tracing is allowed
        if may_trace_sp():
            if flow:
                self.trace_sp()         # trace modification of SP register
            else:
                recalc_spd(self.cmd.ea) # recalculate SP register for the next insn

        return 1

    # ----------------------------------------------------------------------
    def outop(self, op):
        """
        Generate text representation of an instructon operand.
        This function shouldn't change the database, flags or anything else.
        All these actions should be performed only by the emu() function.
        The output text is placed in the output buffer initialized with init_output_buffer()
        This function uses out_...() functions from ua.hpp to generate the operand text
        Returns: 1-ok, 0-operand is hidden.
        """
        optype = op.type
        fl     = op.specval
        signed = 0
        sz = self.cmd.auxpref & AUX_SIZEMASK

        if optype == o_reg:
            out_register(self.regNames[op.reg])
        elif optype == o_imm:
            out_symbol('#')
            op2 = copy.copy(op)
            if sz == AUX_BYTE:
                op2.value &= 0xFF
            elif sz == AUX_WORD:
                op2.value &= 0xFFFF
            else:
                op2.value &= 0xFFFFF
            OutValue(op2, OOFW_IMM | signed )
        elif optype in [o_near, o_mem]:
            if optype == o_mem and fl == FL_ABSOLUTE:
                out_symbol('&')
            r = out_name_expr(op, op.addr, BADADDR)
            if not r:
                out_tagon(COLOR_ERROR)
                OutLong(op.addr, 16)
                out_tagoff(COLOR_ERROR)
                QueueSet(Q_noName, self.cmd.ea)
        elif optype == o_displ:
            # 16-bit index is signed
            width = OOFW_16
            sign = OOF_SIGNED
            if sz in [AUX_A, AUX_AX]:
                # 20-bit index is not signed
                width = OOFW_24
                sign = 0
            OutValue(op, OOF_ADDR | signed | width )
            out_symbol('(')
            out_register(self.regNames[op.reg])
            out_symbol(')')
        elif optype == o_phrase:
            out_symbol('@')
            out_register(self.regNames[op.reg])
            if fl == FL_AUTOINC:
              out_symbol('+')
        else:
            return False

        return True

    # ----------------------------------------------------------------------
    def out(self):
        """
        Generate text representation of an instruction in 'cmd' structure.
        This function shouldn't change the database, flags or anything else.
        All these actions should be performed only by emu() function.
        Returns: nothing
        """
        # Init output buffer
        buf = idaapi.init_output_buffer(1024)

        # do we need to print a modifier line first?
        if self.cmd.auxpref & (AUX_REPREG | AUX_REPIMM | AUX_ZC):
          if self.cmd.auxpref & AUX_ZC:
            out_line("zc", COLOR_INSN)
            term_output_buffer()
            MakeLine(buf)
            buf = idaapi.init_output_buffer(1024)
          if self.cmd.auxpref & AUX_REPREG:
            out_line("rpt", COLOR_INSN)
            OutChar(' ')
            out_register(self.regNames[self.cmd.segpref])
            term_output_buffer()
            MakeLine(buf)
            buf = idaapi.init_output_buffer(1024)
          if self.cmd.auxpref & AUX_REPIMM:
            out_line("rpt", COLOR_INSN)
            OutChar(' ')
            out_symbol('#')
            out_long(self.cmd.segpref, 10)
            term_output_buffer()
            MakeLine(buf)
            buf = idaapi.init_output_buffer(1024)

        postfix = ""

        # add postfix if necessary
        sz = self.cmd.auxpref & AUX_SIZEMASK
        if sz == AUX_BYTE:
            postfix = ".b"
        elif sz == AUX_WORD:
            postfix = ".w"
        elif sz == AUX_A:
            postfix = ".a"

        # first argument (8) is the width of the mnemonic field
        OutMnem(8, postfix)

        # output first operand
        # kernel will call outop()
        if self.cmd.Op1.type != o_void:
            out_one_operand(0)

        # output the rest of operands separated by commas
        for i in xrange(1, 3):
            if self.cmd[i].type == o_void:
                break
            out_symbol(',')
            OutChar(' ')
            out_one_operand(i)

        term_output_buffer()
        cvar.gl_comm = 1 # generate comment at the next call to MakeLine()
        MakeLine(buf)

    # ----------------------------------------------------------------------
    # fill operand fields from decoded instruction parts
    # op:  operand to be filled in
    # reg: register number
    # A:   adressing mode
    # BW:  value of the B/W (byte/word) field
    #      can be DLEN_AWORD for 20-bit instructions
    # is_source: True if filling source operand
    # is_cg: can use constant generator
    # extw: 20-bit extension word
    def fill_op(self, op, reg, A, BW, is_source, is_cg = False, extw = None):
        op.reg = reg
        topaddr = 0  # top 4 bits of an address value
        if extw:
          AL = BIT(extw, 6)
          if AL == 0 and BW == 1:
            BW = DLEN_AWORD
          if is_source:
            topaddr = BITS(extw, 10, 7)
          else:
            topaddr = BITS(extw,  3, 0)
        if BW == DLEN_WORD:
          op.dtyp = dt_word
        elif BW == DLEN_BYTE:
          op.dtyp = dt_byte
        else:
          # 20-bit
          op.dtyp = dt_dword
        if is_cg:
            # check for constant generators
            if reg == self.ireg_SR and A >= 2 and A <= 3:
                op.type = o_imm
                op.value = [4, 8] [A-2]
                return
            elif reg == self.ireg_R3:
                op.type = o_imm
                op.value = [0, 1, 2, -1] [A]
                return
        if A == AM_REGISTER:
            # register mode
            op.type = o_reg
            op.dtyp = dt_word
        elif A == AM_INDEXED:
            # indexed mode
            if reg == self.ireg_SR:
                # absolute address mode
                op.type = o_mem
                op.specval = FL_ABSOLUTE
                op.offb = self.cmd.size
                op.addr = ua_next_word() | (topaddr << 16)
            else:
                # map it to IDA's displacement
                op.type = o_displ
                op.offb = self.cmd.size
                pcval   = self.cmd.ip + self.cmd.size
                op.addr = ua_next_word() | (topaddr << 16)
                if reg == self.ireg_PC:
                  # symbolic addressing mode: address = PC + simm16
                  # 1) if PC is below 64K, the result is wrapped to be below 64K
                  # 2) if PC is above 64K, the result is used as-is (can be below or above 64K)
                  # 3) for MSP430X instructions delta is simm20, result not wrapped
                  # apparently the PC value is the address of the index word, not next instruction!
                  if extw:
                      op.addr = SIGNEXT(op.addr, 20) + pcval
                  else:
                      op.addr = SIGNEXT(op.addr, 16) + pcval
                      if pcval < 0x10000:
                        op.addr &= 0xFFFF
                  op.type = o_mem
                  op.specval = FL_SYMBOLIC
        elif A == AM_INDIRECT:
            # Indirect register mode
            # map it to o_phrase
            op.type = o_phrase
            op.specval = FL_INDIRECT
        elif A == AM_AUTOINC:
            # Indirect autoincrement
            # map it to o_phrase
            if reg == self.ireg_PC:
                #this is actually immediate mode
                op.dtyp = dt_dword if extw else dt_word
                op.type = o_imm
                op.offb = self.cmd.size
                op.value = ua_next_word() | (topaddr << 16)
            else:
                op.type = o_phrase
                op.specval = FL_AUTOINC
        elif A in [AM_IMM20, AM_ABS20, AM_SYM20]:
            # reg is the high 4 bits, low 16 bits follow
            val = (reg << 16) | ua_next_word()
            if A == AM_IMM20:
              op.dtyp = dt_dword
              op.value = val
              op.type = o_imm
            else:
              # &abs20
              op.addr = val
              op.type = o_mem
              if A == AM_SYM20:
                # symbolic addressing mode: address = PC + imm20
                # no sign-extension or wrapping is done
                pcval = cmd.ip + cmd.size
                op.addr += pcval
                op.specval = FL_SYMBOLIC                
              else:
                op.specval = FL_ABSOLUTE
        else:
            warning("bad A(%d) in fill_op" % A)

    # ----------------------------------------------------------------------
    def handle_reg_extw(self, extw):
        #  Register Mode Extension Word
        #   15 ... 12 11  10 9   8   7    6   5    4   3  0
        #  +---------+--------+----+---+-----+---+---+------+
        #  |  0001   | 1 | 00 | ZC | # | A/L | 0 | 0 | R/n-1|
        #  +---------+--------+----+---+-----+---+---+------+
        ZC = BIT(extw, 8)
        repreg = BIT(extw, 7)
        rep = BITS(extw, 3, 0)
        if rep:
          if repreg:
            self.cmd.auxpref |= AUX_REPREG
            self.cmd.segpref = rep
          else:                        
            self.cmd.auxpref |= AUX_REPIMM
            self.cmd.segpref = rep + 1
        if ZC:
          if self.cmd.itype == self.itype_rrcx:
            self.cmd.itype = self.itype_rrux
          else:
            self.cmd.auxpref |= AUX_ZC

    # ----------------------------------------------------------------------
    def decode_format_I(self, w, extw):
        #  Double-Operand (Format I) Instructions
        #
        #   15 ... 12 11 ... 8   7    6   5  4 3    0
        #  +---------+--------+----+-----+----+------+
        #  | Op-code |  Rsrc  | Ad | B/W | As | Rdst |
        #  +---------+--------+----+-----+----+------+
        #  |       Source or destination 15:0        |
        #  +-----------------------------------------+
        #  |             Destination 15:0            |
        #  +-----------------------------------------+
        opc  = BITS(w, 15, 12)
        As   = BITS(w, 5, 4)
        Ad   = BIT(w, 7)
        Rsrc = BITS(w, 11, 8)
        Rdst = BITS(w,  3, 0)
        BW   = BIT(w, 6)
        if opc < 4:
            # something went wrong
            self.cmd.size = 0
        else:
            if extw:
              AL = BIT(extw, 6)
              if AL == 0 and BW == 1:
                BW = DLEN_AWORD
              self.cmd.itype = self.itype_movx + (opc-4)
            else:
              self.cmd.itype = self.itype_mov + (opc-4)
        self.fill_op(self.cmd.Op1, Rsrc, As, BW, True,  True,  extw)
        self.fill_op(self.cmd.Op2, Rdst, Ad, BW, False, False, extw)
        self.cmd.auxpref = BW + AUX_WORD
        if extw and As == AM_REGISTER and Ad == AM_REGISTER:
          self.handle_reg_extw(extw)

    # ----------------------------------------------------------------------
    def decode_format_II(self, w, extw):
        #  Single-Operand (Format II) Instructions
        #
        #   15         10 9       7   6   5  4 3    0
        #  +-------------+---------+-----+----+------+
        #  | 0 0 0 1 0 0 | Op-code | B/W | Ad | Rdst |
        #  +-------------+---------+-----+----+------+
        #  |             Destination 15:0            |
        #  +-----------------------------------------+
        opc  = BITS(w, 9, 7)
        Ad   = BITS(w, 5, 4)
        Rdst = BITS(w, 3, 0)
        BW   = BIT(w, 6)
        if opc in [6, 7]:
          if extw:
            return 0
          return self.decode_430x_calla(w)
        if extw:
          AL = BIT(extw, 6)
          if AL == 0 and BW == 1:
            BW = DLEN_AWORD
          self.cmd.itype = self.itype_rrcx + opc
        else:
          self.cmd.itype = self.itype_rrc + opc
        self.fill_op(self.cmd.Op1, Rdst, Ad, BW, False, True, extw)
        self.cmd.auxpref = BW + AUX_WORD
        if self.cmd.itype in [self.itype_swpb, self.itype_sxt, self.itype_call, self.itype_reti]:
            # these commands have no suffix and should have BW set to 0
            if BW == 0:
                self.cmd.auxpref = AUX_NOSUF
                if self.cmd.itype == self.itype_reti:
                    # Ad and Rdst should be 0
                    if Ad == 0 and Rdst == 0:
                        self.cmd.Op1.type = o_void
                    else:
                        # bad instruction
                        self.cmd.itype = self.itype_null
            else:
                # bad instruction
                self.cmd.itype = self.itype_null
        if extw and Ad == AM_REGISTER:
          self.handle_reg_extw(extw)

    # ----------------------------------------------------------------------
    def decode_jump(self, w):
        #  Jump Instructions
        #
        #   15     13 12   10 9                    0
        #  +---------+-------+----------------------+
        #  |  0 0 1  |   C   |  10-bit PC offset    |
        #  +---------+-------+----------------------+
        C    = BITS(w, 12, 10)
        offs = BITS(w,  9,  0)
        offs = SIGNEXT(offs, 10)
        self.cmd.Op1.type = o_near
        self.cmd.Op1.addr = self.cmd.ea + 2 + offs*2
        self.cmd.itype = self.itype_jnz + C

    # ----------------------------------------------------------------------
    def decode_430x_mova(self, w):
        #  MSP430X Address Instructions
        # 15    12  11 8  7     4  3 0
        #  0 0 0 0  src   0 0 0 0  dst  MOVA @Rsrc,Rdst
        #  0 0 0 0  src   0 0 0 1  dst  MOVA @Rsrc+,Rdst
        #  0 0 0 0  abs   0 0 1 0  dst  MOVA &abs20,Rdst
        #  0 0 0 0  src   0 0 1 1  dst  MOVA x(Rsrc),Rdst
                                   
        #  0 0 0 0 n-1 00  0 1 0 0 dst RRCM.A #n,Rdst
        #  0 0 0 0 n-1 01  0 1 0 0 dst RRAM.A #n,Rdst
        #  0 0 0 0 n-1 10  0 1 0 0 dst RLAM.A #n,Rdst
        #  0 0 0 0 n-1 11  0 1 0 0 dst RRUM.A #n,Rdst

        #  0 0 0 0 n-1 00  0 1 0 1 dst RRCM.W #n,Rdst
        #  0 0 0 0 n-1 01  0 1 0 1 dst RRAM.W #n,Rdst
        #  0 0 0 0 n-1 10  0 1 0 1 dst RLAM.W #n,Rdst
        #  0 0 0 0 n-1 11  0 1 0 1 dst RRUM.W #n,Rdst

        #  0 0 0 0  src   0 1 1 0  abs  MOVA Rsrc,&abs20
        #  0 0 0 0  src   0 1 1 1  dst  MOVA Rsrc,X(Rdst)

        #  0 0 0 0  imm   1 0 0 0  dst  MOVA #imm20,Rdst
        #  0 0 0 0  imm   1 0 0 1  dst  CMPA #imm20,Rdst
        #  0 0 0 0  imm   1 0 1 0  dst  ADDA #imm20,Rdst
        #  0 0 0 0  imm   1 0 1 1  dst  SUBA #imm20,Rdst                                   
        #  0 0 0 0  src   1 1 0 0  dst  MOVA Rsrc,Rdst
        #  0 0 0 0  src   1 1 0 1  dst  CMPA Rsrc,Rdst
        #  0 0 0 0  src   1 1 1 0  dst  ADDA Rsrc,Rdst
        #  0 0 0 0  src   1 1 1 1  dst  SUBA Rsrc,Rdst

        opc  = BITS(w, 7, 4)
        Rsrc = BITS(w, 11, 8)
        Rdst = BITS(w,  3, 0)
        tbl = [
          # itype, operands addressing modes
          # indexed by opcode[7:4]
          [self.itype_mova, AM_INDIRECT, AM_REGISTER], # 0000 MOVA @Rsrc,Rdst
          [self.itype_mova, AM_AUTOINC,  AM_REGISTER], # 0001 MOVA @Rsrc+,Rdst
          [self.itype_mova, AM_ABS20,    AM_REGISTER], # 0010 MOVA &abs20,Rdst
          [self.itype_mova, AM_INDEXED,  AM_REGISTER], # 0011 MOVA X(Rsrc),Rdst
          [-1,              -1,          -1         ], # 0100 Rxxx.A #n, Rdst
          [-1,              -1,          -1         ], # 0101 Rxxx.W #n, Rdst
          [self.itype_mova, AM_REGISTER, AM_ABS20   ], # 0110 MOVA Rsrc, &abs20
          [self.itype_mova, AM_REGISTER, AM_INDEXED ], # 0111 MOVA Rsrc, X(Rdst)
          [self.itype_mova, AM_IMM20,    AM_REGISTER], # 1000 MOVA #imm20, Rdst
          [self.itype_cmpa, AM_IMM20,    AM_REGISTER], # 1001 CMPA #imm20, Rdst
          [self.itype_adda, AM_IMM20,    AM_REGISTER], # 1010 ADDA #imm20, Rdst
          [self.itype_suba, AM_IMM20,    AM_REGISTER], # 1011 SUBA #imm20, Rdst
          [self.itype_mova, AM_REGISTER, AM_REGISTER], # 1100 MOVA Rsrc, Rdst
          [self.itype_cmpa, AM_REGISTER, AM_REGISTER], # 1101 CMPA Rsrc, Rdst
          [self.itype_adda, AM_REGISTER, AM_REGISTER], # 1110 ADDA Rsrc, Rdst
          [self.itype_suba, AM_REGISTER, AM_REGISTER], # 1111 SUBA Rsrc, Rdst
        ]
        row = tbl[opc]
        if row[0] != -1:
          self.cmd.itype = row[0]
          self.fill_op(self.cmd.Op1, Rsrc, row[1], 2, True,  True)
          self.fill_op(self.cmd.Op2, Rdst, row[2], 2, False, False)
          self.cmd.auxpref = AUX_AX
        else:
          # src[3:2] == n-1
          # src[1:0] == insn id
          self.cmd.itype = self.itype_rrcm + (Rsrc & 0b11)
          self.cmd.Op1.type = o_imm
          self.cmd.Op1.dtyp = dt_byte
          self.cmd.Op1.value = (Rsrc>>2) + 1
          # opc[0]: 0=.A, 1=.W
          BW = 0 if (opc & 1) else 2
          self.fill_op(self.cmd.Op2, Rdst, AM_REGISTER, BW, False, False)
          if opc & 1:
            self.cmd.auxpref = AUX_A
          else:
            self.cmd.auxpref = AUX_WORD

    # ----------------------------------------------------------------------
    def decode_430x_calla(self, w):
        #  MSP430X CALLA Instruction
        opc  = BITS(w, 7, 4)
        Rdst = BITS(w, 3, 0)
        tbl = [
          # itype, dest addressing mode
          # indexed by opcode[7:4]
          [self.itype_reti,  -1         ], # 0000 RETI
          [self.itype_null,  -1         ], # 0001 ----
          [self.itype_null,  -1         ], # 0010 ----
          [self.itype_null,  -1         ], # 0011 ----
          [self.itype_calla, AM_REGISTER], # 0100 CALLA Rdst
          [self.itype_calla, AM_INDEXED ], # 0101 CALLA X(Rdst)
          [self.itype_calla, AM_INDIRECT], # 0110 CALLA @Rdst
          [self.itype_calla, AM_AUTOINC ], # 0111 CALLA @Rdst+
          [self.itype_calla, AM_ABS20   ], # 1000 CALLA &abs20
          [self.itype_calla, AM_SYM20   ], # 1001 CALLA sym20 (imm20+PC)
          [self.itype_null,  -1         ], # 1010 ----
          [self.itype_calla, AM_IMM20   ], # 1011 CALLA #imm20
          [self.itype_null,  -1         ], # 1100 ----
          [self.itype_null,  -1         ], # 1101 ----
          [self.itype_null,  -1         ], # 1110 ----
          [self.itype_null,  -1         ], # 1111 ----
        ]
        row = tbl[opc]
        self.cmd.itype = row[0]
        if row[1] != -1:
          self.fill_op(self.cmd.Op1, Rdst, row[1], DLEN_AWORD, True, False)
          self.cmd.auxpref = AUX_AX

    # ----------------------------------------------------------------------
    def decode_430x_pushm(self, w):
        #  MSP430X PUSHM/POPM Instructions
        #  15  10 98 7 4 3 0
        #  000101 00 n-1 dst      PUSHM.A #n,Rdst
        #  000101 01 n-1 dst      PUSHM.W #n,Rdst
        #  000101 10 n-1 dst-n+1  POPM.A  #n, Rdst
        #  000101 11 n-1 dst-n+1  POPM.W  #n, Rdst
        opc  = BITS(w, 7, 4)
        Rdst = BITS(w, 3, 0)
        
        ispop = BIT(w, 9)
        self.cmd.itype   = [self.itype_pushm, self.itype_popm] [ispop]
        n    = BITS(w, 7, 4) + 1
        Rdst = BITS(w, 3, 0)
        if ispop:
          Rdst += n - 1
        self.cmd.Op1.type = o_imm
        self.cmd.Op1.dtyp = dt_byte
        self.cmd.Op1.value = n
        isw = BIT(w, 8)
        BW = 0 if isw else 2
        self.fill_op(self.cmd.Op2, Rdst, AM_REGISTER, BW, False, False)
        self.cmd.auxpref = [AUX_A, AUX_WORD] [isw]

    # ----------------------------------------------------------------------
    # does operand match tuple m? (type, value)
    def match_op(self, op, m):
        if m == None:
            return True
        if op.type != m[0]:
            return False
        if op.type == o_imm:
            return op.value == m[1]
        elif op.type in [o_reg, o_phrase]:
            return op.reg == m[1]
        else:
            return false

    # ----------------------------------------------------------------------
    # replace some instructions by simplified mnemonics ("emulated" in TI terms)
    def simplify(self):
        # source mnemonic mapped to a list of matches:
        #   match function, new mnemonic, new operand
        maptbl = {
            self.itype_addc: [
                # addc #0, dst -> adc dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_adc, 2 ],
                # addc dst, dst -> rlc dst
                [ lambda: same_op(self.cmd.Op1, self.cmd.Op2), self.itype_rlc, 1 ],
            ],
            self.itype_addcx: [
                # addcx #0, dst -> adcx dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_adcx, 2 ],
                # addcx dst, dst -> rlcx dst
                [ lambda: same_op(self.cmd.Op1, self.cmd.Op2), self.itype_rlcx, 1 ],
            ],
            self.itype_mov: [
                # mov #0, R3 -> nop
                [ lambda: is_imm(self.cmd.Op1, 0) and self.cmd.Op2.is_reg(self.ireg_R3), self.itype_nop, 0 ],
                # mov #0, dst -> clr dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_clr, 2 ],
                # mov @SP+, PC -> ret
                [ lambda: is_autoinc(self.cmd.Op1, self.ireg_SP) and self.cmd.Op2.is_reg(self.ireg_PC), self.itype_ret, 0 ],
                # mov @SP+, dst -> pop dst
                [ lambda: is_autoinc(self.cmd.Op1, self.ireg_SP), self.itype_pop, 2 ],
                # mov dst, PC -> br dst
                [ lambda: self.is_movpc(), self.itype_br, 1 ],
            ],
            self.itype_movx: [
                # movx #0, dst -> clrx dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_clrx, 2 ],
            ],
            self.itype_mova: [
                # mova #0, dst -> clra dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_clra, 2 ],
                # mova @SP+, PC -> reta
                [ lambda: is_autoinc(self.cmd.Op1, self.ireg_SP) and self.cmd.Op2.is_reg(self.ireg_PC), self.itype_reta, 0 ],
                # mova @SP+, dst -> popa dst
                [ lambda: is_autoinc(self.cmd.Op1, self.ireg_SP), self.itype_popa, 2 ],
                # mova dst, PC -> bra dst
                [ lambda: self.cmd.Op2.is_reg(self.ireg_PC), self.itype_bra, 1 ],
            ],
            self.itype_bic: [
                # bic #1, SR -> clrc
                [ lambda: is_imm(self.cmd.Op1, 1) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_clrc, 0 ],
                # bic #2, SR -> clrz
                [ lambda: is_imm(self.cmd.Op1, 2) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_clrz, 0 ],
                # bic #4, SR -> clrn
                [ lambda: is_imm(self.cmd.Op1, 4) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_clrn, 0 ],
                # bic #8, SR -> dint
                [ lambda: is_imm(self.cmd.Op1, 8) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_dint, 0 ],
            ],
            self.itype_bis: [
                # bis #1, SR -> setc
                [ lambda: is_imm(self.cmd.Op1, 1) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_setc, 0 ],
                # bis #2, SR -> setz
                [ lambda: is_imm(self.cmd.Op1, 2) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_setz, 0 ],
                # bis #4, SR -> setn
                [ lambda: is_imm(self.cmd.Op1, 4) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_setn, 0 ],
                # bis #8, SR -> eint
                [ lambda: is_imm(self.cmd.Op1, 8) and self.cmd.Op2.is_reg(self.ireg_SR), self.itype_eint, 0 ],
            ],
            self.itype_dadd: [
                # dadd #0, dst -> dadc dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_dadc, 2 ],
            ],
            self.itype_daddx: [
                # daddx #0, dst -> dadcx dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_dadcx, 2 ],
            ],
            self.itype_sub: [
                # sub #1, dst -> dec dst
                [ lambda: is_imm(self.cmd.Op1, 1), self.itype_dec, 2 ],
                # sub #2, dst -> decd dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_decd, 2 ],
            ],
            self.itype_subx: [
                # subx #1, dst -> decx dst
                [ lambda: is_imm(self.cmd.Op1, 1), self.itype_decx, 2 ],
                # subx #2, dst -> decdx dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_decdx, 2 ],
            ],
            self.itype_suba: [
                # suba #2, dst -> decda dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_decda, 2 ],
            ],
            self.itype_subc: [
                # subc #0, dst -> sbc dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_sbc, 2 ],
            ],
            self.itype_subcx: [
                # subcx #0, dst -> sbcx dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_sbcx, 2 ],
            ],
            self.itype_add: [
                # add #1, dst -> inc dst
                [ lambda: is_imm(self.cmd.Op1, 1), self.itype_inc, 2 ],
                # add #2, dst -> incd dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_incd, 2 ],
                # add dst, dst -> rla dst
                [ lambda: same_op(self.cmd.Op1, self.cmd.Op2), self.itype_rla, 1 ],
            ],
            self.itype_adda: [
                # adda #2, dst -> incda dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_incda, 2 ],
            ],
            self.itype_addx: [
                # addx #1, dst -> incx dst
                [ lambda: is_imm(self.cmd.Op1, 1), self.itype_incx, 2 ],
                # addx #2, dst -> incdx dst
                [ lambda: is_imm(self.cmd.Op1, 2), self.itype_incdx, 2 ],
                # addx dst, dst -> rlax dst
                [ lambda: same_op(self.cmd.Op1, self.cmd.Op2), self.itype_rlax, 1 ],
            ],
            self.itype_xor: [
                # xor #-1, dst -> inv dst
                [ lambda: is_imm(self.cmd.Op1, -1), self.itype_inv, 2 ],
            ],
            self.itype_xorx: [
                # xorx #-1, dst -> invx dst
                [ lambda: is_imm(self.cmd.Op1, -1), self.itype_invx, 2 ],
            ],
            self.itype_cmp: [
                # cmp #0, dst -> tst dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_tst, 2 ],
            ],
            self.itype_cmpx: [
                # cmpx #0, dst -> tstx dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_tstx, 2 ],
            ],
            self.itype_cmpa: [
                # cmpa #0, dst -> tsta dst
                [ lambda: is_imm(self.cmd.Op1, 0), self.itype_tsta, 2 ],
            ],
        }

        # instructions which should have no suffix
        nosuff = [self.itype_ret,  self.itype_reta, self.itype_br, self.itype_bra,
                  self.itype_clrc, self.itype_clrn, self.itype_clrz, self.itype_dint,
                  self.itype_eint, self.itype_clrc, self.itype_nop, self.itype_pop,
                  self.itype_popa, self.itype_setc, self.itype_setn, self.itype_setz, ]

        if self.cmd.itype in maptbl:
            for m in maptbl[self.cmd.itype]:
                if m[0]():
                    # matched instruction; replace the itype
                    self.cmd.itype = m[1]
                    if m[2] == 0:
                        # remove the operands
                        self.cmd.Op1.type = o_void
                    elif m[2] == 2:
                        # replace first operand with the second
                        self.cmd.Op1.assign(self.cmd.Op2)
                    # remove the second operand, if any
                    self.cmd.Op2.type = o_void
                    # remove suffix if necessary
                    if self.cmd.itype in nosuff and self.cmd.auxpref == AUX_WORD:
                        self.cmd.auxpref = 0
                    break

    # ----------------------------------------------------------------------
    def ana(self):
        """
        Decodes an instruction into self.cmd.
        Returns: self.cmd.size (=the size of the decoded instruction) or zero
        """
        if (self.cmd.ea & 1) != 0:
            return 0
        w = ua_next_word()
        extw = None        
        if BITS(w, 15, 11) == 0b00011:
            # operand extension word
            extw = w
            w = ua_next_word()
        if BITS(w, 15, 10) == 0b000100:
            self.decode_format_II(w, extw)
        elif BITS(w, 15, 10) == 0b000101:
            if extw: return 0
            self.decode_430x_pushm(w)
        elif BITS(w, 15, 13) == 1: # 001
            if extw: return 0
            self.decode_jump(w)
        elif BITS(w, 15, 12) == 0:
            if extw: return 0
            self.decode_430x_mova(w)
        else:
            self.decode_format_I(w, extw)

        self.simplify()
        # Return decoded instruction size or zero
        return self.cmd.size if self.cmd.itype != self.itype_null else 0

    # ----------------------------------------------------------------------
    def init_instructions(self):
        Instructions = []
        i = 0
        for x in self.instruc:
            if x['name'] != '':
                setattr(self, 'itype_' + x['name'], i)
            else:
                setattr(self, 'itype_null', i)
            i += 1

        # icode of the last instruction + 1
        self.instruc_end = len(self.instruc) + 1

        # Icode of return instruction. It is ok to give any of possible return
        # instructions
        self.icode_return = self.itype_reti

    # ----------------------------------------------------------------------
    def init_registers(self):
        """This function parses the register table and creates corresponding ireg_XXX constants"""

        # Registers definition
        self.regNames = [
            # General purpose registers
            "PC", # R0
            "SP", # R1
            "SR", # R2, CG1
            "R3", # CG2
            "R4",
            "R5",
            "R6",
            "R7",
            "R8",
            "R9",
            "R10",
            "R11",
            "R12",
            "R13",
            "R14",
            "R15",
            # Fake segment registers
            "CS",
            "DS"
        ]

        # Create the ireg_XXXX constants
        for i in xrange(len(self.regNames)):
            setattr(self, 'ireg_' + self.regNames[i], i)

        # Segment register information (use virtual CS and DS registers if your
        # processor doesn't have segment registers):
        self.regFirstSreg = self.ireg_CS
        self.regLastSreg  = self.ireg_DS

        # number of CS register
        self.regCodeSreg = self.ireg_CS

        # number of DS register
        self.regDataSreg = self.ireg_DS

    # ----------------------------------------------------------------------
    def __init__(self):
        idaapi.processor_t.__init__(self)
        self.init_instructions()
        self.init_registers()

# ----------------------------------------------------------------------
# Every processor module script must provide this function.
# It should return a new instance of a class derived from idaapi.processor_t
def PROCESSOR_ENTRY():
    return msp430_processor_t()
