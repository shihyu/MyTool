# INSTRUCTIONS: save as ~/.gdbinit
#
#
# DESCRIPTION: A user-friendly gdb configuration file.
#
#
# REVISION : 7.1
#
#
# CONTRIBUTORS: mammon_, elaine, pusillus, mong, zhang le, l0kit,
#               truthix the cyberpunk
#
# FEEDBACK: https://www.reverse-engineering.net
#           The Linux Area
#           Topic: "+HCU's .gdbinit Version 7.1 -- humble announce"
#
#
# NOTES: 'help user' in gdb will list the commands/descriptions in this file
#        'context on' now enables auto-display of context screen
#
# CHANGELOG:
#
#   Version 7.1
#     Fixed serious (and old) bug in dd and datawin, causing dereference of
#     obviously invalid address. See below:
#     gdb$ dd 0xffffffff
#     FFFFFFFF : Cannot access memory at address 0xffffffff
#    
#   Version 7.0
#     Added cls command.
#     Improved documentation of many commands.
#     Removed bp_alloc, was neither portable nor usefull.
#     Checking of passed argument(s) in these commands:
#       contextsize-stack, contextsize-data, contextsize-code
#       bp, bpc, bpe, bpd, bpt, bpm, bhb,...
#     Fixed bp and bhb inconsistencies, look at * signs in Version 6.2
#     Bugfix in bhb command, changed "break" to "hb" command body
#     Removed $SHOW_CONTEXT=1 from several commands, this variable
#     should only be controlled globally with context-on and context-off
#     Improved stack, func, var and sig, dis, n, go,...
#     they take optional argument(s) now
#     Fixed wrong $SHOW_CONTEXT assignment in context-off
#     Fixed serious bug in cft command, forgotten ~ sign
#     Fixed these bugs in step_to_call:
#       1) the correct logging sequence is:
#          set logging file > set logging redirect > set logging on
#       2) $SHOW_CONTEXT is now correctly restored from $_saved_ctx
#     Fixed these bugs in trace_calls:
#       1) the correct logging sequence is:
#          set logging file > set logging overwrite >
#          set logging redirect > set logging on
#       2) removed the "clean up trace file" part, which is not needed now,
#          stepi output is properly redirected to /dev/null
#       3) $SHOW_CONTEXT is now correctly restored from $_saved_ctx
#     Fixed bug in trace_run:
#       1) $SHOW_CONTEXT is now correctly restored from $_saved_ctx
#     Fixed print_insn_type -- removed invalid semicolons!, wrong value checking,
#     Added TODO entry regarding the "u" command
#     Changed name from gas_assemble to assemble_gas due to consistency
#     Output from assemble and assemble_gas is now similar, because i made
#     both of them to use objdump, with respect to output format (AT&T|Intel).
#     Whole code was checked and made more consistent, readable/maintainable.
#
#   Version 6.2
#     Add global variables to allow user to control stack, data and code window sizes
#     Increase readability for registers
#     Some corrections (hexdump, ddump, context, cfp, assemble, gas_asm, tips, prompt)
#   
#   Version 6.1-color-user
#     Took the Gentoo route and ran sed s/user/user/g
#
#   Version 6.1-color
#     Added color fixes from
#       http://gnurbs.blogsome.com/2006/12/22/colorizing-mamons-gdbinit/
#
#   Version 6.1
#     Fixed filename in step_to_call so it points to /dev/null
#     Changed location of logfiles from /tmp  to ~
#
#   Version 6
#     Added print_insn_type, get_insn_type, context-on, context-off commands
#     Added trace_calls, trace_run, step_to_call commands
#     Changed hook-stop so it checks $SHOW_CONTEXT variable
#
#   Version 5
#     Added bpm, dump_bin, dump_hex, bp_alloc commands
#     Added 'assemble' by elaine, 'gas_asm' by mong
#     Added Tip Topics for aspiring users ;)
#
#   Version 4
#     Added eflags-changing insns by pusillus
#     Added bp, nop, null, and int3 patch commands, also hook-stop
#
#   Version 3
#     Incorporated elaine's if/else goodness into the hex/ascii dump
#
#   Version 2
#     Radix bugfix by elaine
#
#   TODO:
#     Possible removal of "u" command, info udot is missing in gdb 6.8-debian
#     Add dump, append, set write, etc commands
#     Add more tips !




# ______________window size control___________
define contextsize-stack
    if $argc != 1
        help contextsize-stack
    else
        set $CONTEXTSIZE_STACK = $arg0
    end
end
document contextsize-stack
Set stack dump window size to NUM lines.
Usage: contextsize-stack NUM
end


define contextsize-data
    if $argc != 1
        help contextsize-data
    else
        set $CONTEXTSIZE_DATA = $arg0
    end
end
document contextsize-data
Set data dump window size to NUM lines.
Usage: contextsize-data NUM
end


define contextsize-code
    if $argc != 1
        help contextsize-code
    else
        set $CONTEXTSIZE_CODE = $arg0
    end
end
document contextsize-code
Set code window size to NUM lines.
Usage: contextsize-code NUM
end




# _____________breakpoint aliases_____________
define bpl
    info breakpoints
end
document bpl
List all breakpoints.
end


define bp
    if $argc != 1
        help bp
    else
        break $arg0
    end
end
document bp
Set breakpoint.
Usage: bp LOCATION
LOCATION may be a line number, function name, or "*" and an address.
end


define bpc 
    if $argc != 1
        help bpc
    else
        clear $arg0
    end
end
document bpc
Clear breakpoint.
Usage: bpc LOCATION
LOCATION may be a line number, function name, or "*" and an address.
end


define bpe
    if $argc != 1
        help bpe
    else
        enable $arg0
    end
end
document bpe
Enable breakpoint with number NUM.
Usage: bpe NUM
end


define bpd
    if $argc != 1
        help bpd
    else
        disable $arg0
    end
end
document bpd
Disable breakpoint with number NUM.
Usage: bpd NUM
end


define bpt
    if $argc != 1
        help bpt
    else
        tbreak $arg0
    end
end
document bpt
Set a temporary breakpoint.
Will be deleted when hit!
Usage: bpt LOCATION
LOCATION may be a line number, function name, or "*" and an address.
end


define bpm
    if $argc != 1
        help bpm
    else
        awatch $arg0
    end
end
document bpm
Set a read/write breakpoint on EXPRESSION, e.g. *address.
Usage: bpm EXPRESSION
end


define bhb
    if $argc != 1
        help bhb
    else
        hb $arg0
    end
end
document bhb
Set hardware assisted breakpoint.
Usage: bhb LOCATION
LOCATION may be a line number, function name, or "*" and an address.
end




# ______________process information____________
define argv
    show args
end
document argv
Print program arguments.
end


define stack
    if $argc == 0
        info stack
    end
    if $argc == 1
        info stack $arg0
    end
    if $argc > 1
        help stack
    end
end
document stack
Print backtrace of the call stack, or innermost COUNT frames.
Usage: stack <COUNT>
end


define frame
    info frame
    info args
    info locals
end
document frame
Print stack frame.
end


define flags
    if (($eflags >> 0xB) & 1)
        printf "O "
    else
        printf "o "
    end
    if (($eflags >> 0xA) & 1)
        printf "D "
    else
        printf "d "
    end
    if (($eflags >> 9) & 1)
        printf "I "
    else
        printf "i "
    end
    if (($eflags >> 8) & 1)
        printf "T "
    else
        printf "t "
    end
    if (($eflags >> 7) & 1)
        printf "S "
    else
        printf "s "
    end
    if (($eflags >> 6) & 1)
        printf "Z "
    else
        printf "z "
    end
    if (($eflags >> 4) & 1)
        printf "A "
    else
        printf "a "
    end
    if (($eflags >> 2) & 1)
        printf "P "
    else
        printf "p "
    end
    if ($eflags & 1)
        printf "C "
    else
        printf "c "
    end
    printf "\n"
end
document flags
Print flags register.
end


define eflags
    printf "     OF <%d>  DF <%d>  IF <%d>  TF <%d>",\
           (($eflags >> 0xB) & 1), (($eflags >> 0xA) & 1), \
           (($eflags >> 9) & 1), (($eflags >> 8) & 1)
    printf "  SF <%d>  ZF <%d>  AF <%d>  PF <%d>  CF <%d>\n",\
           (($eflags >> 7) & 1), (($eflags >> 6) & 1),\
           (($eflags >> 4) & 1), (($eflags >> 2) & 1), ($eflags & 1)
    printf "     ID <%d>  VIP <%d> VIF <%d> AC <%d>",\
           (($eflags >> 0x15) & 1), (($eflags >> 0x14) & 1), \
           (($eflags >> 0x13) & 1), (($eflags >> 0x12) & 1)
    printf "  VM <%d>  RF <%d>  NT <%d>  IOPL <%d>\n",\
           (($eflags >> 0x11) & 1), (($eflags >> 0x10) & 1),\
           (($eflags >> 0xE) & 1), (($eflags >> 0xC) & 3)
end
document eflags
Print eflags register.
end


define reg
    printf "  "
    echo \033[32m
    printf "EAX:"
    echo \033[0m
    printf " %08X  ", $eax
    echo \033[32m
    printf "EBX:"
    echo \033[0m
    printf " %08X  ", $ebx
    echo \033[32m
    printf "ECX:"
    echo \033[0m
    printf " %08X  ", $ecx
    echo \033[32m
    printf "EDX:"
    echo \033[0m
    printf " %08X  ", $edx
    echo \033[31m
    flags
    echo \033[0m
    printf "  "
    echo \033[32m
    printf "ESI:"
    echo \033[0m
    printf " %08X  ", $esi
    echo \033[32m
    printf "EDI:"
    echo \033[0m
    printf " %08X  ", $edi
    echo \033[32m
    printf "EBP:"
    echo \033[0m
    printf " %08X  ", $ebp
    echo \033[32m
    printf "ESP:"
    echo \033[0m
    printf " %08X  ", $esp
    echo \033[32m
    printf "EIP:"
    echo \033[0m
    printf " %08X\n  ", $eip
    echo \033[32m
    printf "CS:"
    echo \033[0m
    printf " %04X  ", $cs
    echo \033[32m
    printf "DS:"
    echo \033[0m
    printf " %04X  ", $ds
    echo \033[32m
    printf "ES:"
    echo \033[0m
    printf " %04X  ", $es
    echo \033[32m
    printf "FS:"
    echo \033[0m
    printf " %04X  ", $fs
    echo \033[32m
    printf "GS:"
    echo \033[0m
    printf " %04X  ", $gs
    echo \033[32m
    printf "SS:"
    echo \033[0m
    printf " %04X\n", $ss
end
document reg
Print CPU registers.
end


define func
    if $argc == 0
        info functions
    end
    if $argc == 1
        info functions $arg0
    end
    if $argc > 1
        help func
    end
end
document func
Print all function names in target, or those matching REGEXP.
Usage: func <REGEXP>
end


define var
    if $argc == 0
        info variables
    end
    if $argc == 1
        info variables $arg0
    end
    if $argc > 1
        help var
    end
end
document var
Print all global and static variable names (symbols), or those matching REGEXP.
Usage: var <REGEXP>
end


define lib
    info sharedlibrary
end
document lib
Print shared libraries linked to target.
end


define sig
    if $argc == 0
        info signals
    end
    if $argc == 1
        info signals $arg0
    end
    if $argc > 1
        help sig
    end
end
document sig
Print what debugger does when program gets various signals.
Specify a SIGNAL as argument to print info on that signal only.
Usage: sig <SIGNAL>
end


define thread
    info threads
end
document thread
Print threads in target.
end


define u
    info udot
end
document u
Print kernel 'user' struct for target.
end


define dis
    if $argc == 0
        disassemble
    end
    if $argc == 1
        disassemble $arg0
    end
    if $argc == 2
        disassemble $arg0 $arg1
    end 
    if $argc > 2
        help dis
    end
end
document dis
Disassemble a specified section of memory.
Default is to disassemble the function surrounding the PC (program counter)
of selected frame. With one argument, ADDR1, the function surrounding this
address is dumped. Two arguments are taken as a range of memory to dump.
Usage: dis <ADDR1> <ADDR2>
end




# __________hex/ascii dump an address_________
define ascii_char
    if $argc != 1
        help ascii_char
    else
        # thanks elaine :)
        set $_c = *(unsigned char *)($arg0)
        if ($_c < 0x20 || $_c > 0x7E)
            printf "."
        else
            printf "%c", $_c
        end
    end
end
document ascii_char
Print ASCII value of byte at address ADDR.
Print "." if the value is unprintable.
Usage: ascii_char ADDR
end


define hex_quad
    if $argc != 1
        help hex_quad
    else
        printf "%02X %02X %02X %02X  %02X %02X %02X %02X", \
               *(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),     \
               *(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3), \
               *(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5), \
               *(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
    end
end
document hex_quad
Print eight hexadecimal bytes starting at address ADDR.
Usage: hex_quad ADDR
end


define hexdump
    if $argc != 1
        help hexdump
    else
        echo \033[1;34m
        printf "%08X : ", $arg0
        echo \033[0;34m
        hex_quad $arg0
        echo \033[1;34m
        printf " - "
        echo \033[0;34m
        hex_quad $arg0+8
        printf " "
        echo \033[1;34m
        ascii_char $arg0+0x0
        ascii_char $arg0+0x1
        ascii_char $arg0+0x2
        ascii_char $arg0+0x3
        ascii_char $arg0+0x4
        ascii_char $arg0+0x5
        ascii_char $arg0+0x6
        ascii_char $arg0+0x7
        ascii_char $arg0+0x8
        ascii_char $arg0+0x9
        ascii_char $arg0+0xA
        ascii_char $arg0+0xB
        ascii_char $arg0+0xC
        ascii_char $arg0+0xD
        ascii_char $arg0+0xE
        ascii_char $arg0+0xF
        echo \033[0m
        printf "\n"
    end
end
document hexdump
Display a 16-byte hex/ASCII dump of memory at address ADDR.
Usage: hexdump ADDR
end




# _______________data window__________________
define ddump
    if $argc != 1
        help ddump
    else
        echo \033[36m
        printf "[%04X:%08X]------------------------", $ds, $data_addr
        printf "-----------------------------------[data]\n"
        echo \033[0m
        set $_count = 0
        while ($_count < $arg0)
            set $_i = ($_count * 0x10)
            hexdump $data_addr+$_i
            set $_count++
        end
    end
end
document ddump
Display NUM lines of hexdump for address in $data_addr global variable.
Usage: ddump NUM
end


define dd
    if $argc != 1
        help dd
    else
        if ((($arg0 >> 0x18) == 0x40) || (($arg0 >> 0x18) == 0x08) || \
           (($arg0 >> 0x18) == 0xBF))
            set $data_addr = $arg0
            ddump 0x10
        else
            printf "Invalid address: %08X\n", $arg0
        end
    end
end
document dd
Display 16 lines of a hex dump of address starting at ADDR.
Usage: dd ADDR
end


define datawin
    if ((($esi >> 0x18) == 0x40) || (($esi >> 0x18) == 0x08) || \
        (($esi >> 0x18) == 0xBF))
        set $data_addr = $esi
    else
        if ((($edi >> 0x18) == 0x40) || (($edi >> 0x18) == 0x08) || \
            (($edi >> 0x18) == 0xBF))
            set $data_addr = $edi
        else
            if ((($eax >> 0x18) == 0x40) || (($eax >> 0x18) == 0x08) || \
                (($eax >> 0x18) == 0xBF))
                set $data_addr = $eax
            else
                set $data_addr = $esp
            end
        end
    end
    ddump $CONTEXTSIZE_DATA
end
document datawin
Display valid address from one register in data window.
Registers to choose are: esi, edi, eax, or esp.
end




# _______________process context______________
define context
    echo \033[36m
    printf "----------------------------------------"
    printf "----------------------------------[regs]\n"
    echo \033[0m
    reg
    echo \033[36m
    printf "[%04X:%08X]-------------------------", $ss, $esp
    printf "---------------------------------[stack]\n"
    echo \033[0m
    set $context_i = $CONTEXTSIZE_STACK
    while ($context_i > 0)
        set $context_t = $sp + 0x10 * ($context_i - 1)
        hexdump $context_t
        set $context_i--
    end
    datawin
    echo \033[36m
    printf "[%04X:%08X]-------------------------", $cs, $eip
    printf "----------------------------------[code]\n"
    echo \033[37m
    set $context_i = $CONTEXTSIZE_CODE
    if($context_i > 0)
        x /i $pc
        set $context_i--
    end
    while ($context_i > 0)
        x /i
        set $context_i--
    end
    echo \033[36m
    printf "----------------------------------------"
    printf "----------------------------------------\n"
    echo \033[0m
end
document context
Print context window, i.e. regs, stack, ds:esi and disassemble cs:eip.
end


define context-on
    set $SHOW_CONTEXT = 1
    printf "Displaying of context is now ON\n"
end
document context-on
Enable display of context on every program break.
end


define context-off
    set $SHOW_CONTEXT = 0
    printf "Displaying of context is now OFF\n"
end
document context-off
Disable display of context on every program break.
end




# _______________process control______________
define n
    if $argc == 0
        nexti
    end
    if $argc == 1
        nexti $arg0
    end
    if $argc > 1
        help n
    end
end
document n
Step one instruction, but proceed through subroutine calls.
If NUM is given, then repeat it NUM times or till program stops.
This is alias for nexti.
Usage: n <NUM>
end


define go
    if $argc == 0
        stepi
    end
    if $argc == 1
        stepi $arg0
    end
    if $argc > 1
        help go
    end
end
document go
Step one instruction exactly.
If NUM is given, then repeat it NUM times or till program stops.
This is alias for stepi.
Usage: go <NUM>
end


define pret
    finish
end
document pret
Execute until selected stack frame returns (step out of current call).
Upon return, the value returned is printed and put in the value history.
end


define init
    set $SHOW_NEST_INSN = 0
    tbreak _init
    r
end
document init
Run program and break on _init().
end


define start
    set $SHOW_NEST_INSN = 0
    tbreak _start
    r
end
document start
Run program and break on _start().
end


define sstart
    set $SHOW_NEST_INSN = 0
    tbreak __libc_start_main
    r
end
document sstart
Run program and break on __libc_start_main().
Useful for stripped executables.
end


define main
    set $SHOW_NEST_INSN = 0
    tbreak main
    r
end
document main
Run program and break on main().
end




# _______________eflags commands______________
define cfc
    if ($eflags & 1)
        set $eflags = $eflags&~0x1
    else
        set $eflags = $eflags|0x1
    end
end
document cfc
Change Carry Flag.
end


define cfp
    if (($eflags >> 2) & 1)
        set $eflags = $eflags&~0x4
    else
        set $eflags = $eflags|0x4
    end
end
document cfp
Change Parity Flag.
end


define cfa
    if (($eflags >> 4) & 1)
        set $eflags = $eflags&~0x10
    else
        set $eflags = $eflags|0x10
    end
end
document cfa
Change Auxiliary Carry Flag.
end


define cfz
    if (($eflags >> 6) & 1)
        set $eflags = $eflags&~0x40
    else
        set $eflags = $eflags|0x40
    end
end
document cfz
Change Zero Flag.
end


define cfs
    if (($eflags >> 7) & 1)
        set $eflags = $eflags&~0x80
    else
        set $eflags = $eflags|0x80
    end
end
document cfs
Change Sign Flag.
end


define cft
    if (($eflags >> 8) & 1)
        set $eflags = $eflags&~0x100
    else
        set $eflags = $eflags|0x100
    end
end
document cft
Change Trap Flag.
end


define cfi
    if (($eflags >> 9) & 1)
        set $eflags = $eflags&~0x200
    else
        set $eflags = $eflags|0x200
    end
end
document cfi
Change Interrupt Flag.
Only privileged applications (usually the OS kernel) may modify IF.
This only applies to protected mode (real mode code may always modify IF).



end


define cfd
    if (($eflags >>0xA) & 1)
        set $eflags = $eflags&~0x400
    else
        set $eflags = $eflags|0x400
    end
end
document cfd
Change Direction Flag.
end


define cfo
    if (($eflags >> 0xB) & 1)
        set $eflags = $eflags&~0x800
    else
        set $eflags = $eflags|0x800
    end
end
document cfo
Change Overflow Flag.
end




# ____________________patch___________________
define nop
    if $argc != 1
        help nop
    else
        set *(unsigned char *)$arg0 = 0x90
    end
end
document nop
Patch byte at address ADDR to a nop (0x90) instruction.
Usage: nop ADDR
end


define null
    if $argc != 1
        help null
    else
        set *(unsigned char *)$arg0 = 0
    end
end
document null
Patch byte at address ADDR to NULL (0x00).
Usage: null ADDR
end


define int3
    if $argc != 1
        help int3
    else
        set *(unsigned char *)$arg0 = 0xCC
    end
end
document int3
Patch byte at address ADDR to an INT3 (0xCC) instruction.
Usage: int3 ADDR
end




# ____________________cflow___________________
define print_insn_type
    if $argc != 1
        help print_insn_type
    else
        if ($arg0 < 0 || $arg0 > 5)
            printf "UNDEFINED/WRONG VALUE"
        end
        if ($arg0 == 0)
            printf "UNKNOWN"
        end
        if ($arg0 == 1)
            printf "JMP"
        end
        if ($arg0 == 2)
            printf "JCC"
        end
        if ($arg0 == 3)
            printf "CALL"
        end
        if ($arg0 == 4)
            printf "RET"
        end
        if ($arg0 == 5)
            printf "INT"
        end
    end
end
document print_insn_type
Print human-readable mnemonic for the instruction type (usually $INSN_TYPE).
Usage: print_insn_type INSN_TYPE_NUMBER
end


define get_insn_type
    if $argc != 1
        help get_insn_type
    else
        set $INSN_TYPE = 0
        set $_byte1 = *(unsigned char *)$arg0
        if ($_byte1 == 0x9A || $_byte1 == 0xE8)
            # "call"
            set $INSN_TYPE = 3
        end
        if ($_byte1 >= 0xE9 && $_byte1 <= 0xEB)
            # "jmp"
            set $INSN_TYPE = 1
        end
        if ($_byte1 >= 0x70 && $_byte1 <= 0x7F)
            # "jcc"
            set $INSN_TYPE = 2
        end
        if ($_byte1 >= 0xE0 && $_byte1 <= 0xE3 )
            # "jcc"
            set $INSN_TYPE = 2
        end
        if ($_byte1 == 0xC2 || $_byte1 == 0xC3 || $_byte1 == 0xCA || \
            $_byte1 == 0xCB || $_byte1 == 0xCF)
            # "ret"
            set $INSN_TYPE = 4
        end
        if ($_byte1 >= 0xCC && $_byte1 <= 0xCE)
            # "int"
            set $INSN_TYPE = 5
        end
        if ($_byte1 == 0x0F )
            # two-byte opcode
            set $_byte2 = *(unsigned char *)($arg0 + 1)
            if ($_byte2 >= 0x80 && $_byte2 <= 0x8F)
                # "jcc"
                set $INSN_TYPE = 2
            end
        end
        if ($_byte1 == 0xFF)        
            # opcode extension
            set $_byte2 = *(unsigned char *)($arg0 + 1)
            set $_opext = ($_byte2 & 0x38)
            if ($_opext == 0x10 || $_opext == 0x18) 
                # "call"
                set $INSN_TYPE = 3
            end
            if ($_opext == 0x20 || $_opext == 0x28)
                # "jmp"
                set $INSN_TYPE = 1
            end
        end
    end
end
document get_insn_type
Recognize instruction type at address ADDR.
Take address ADDR and set the global $INSN_TYPE variable to
0, 1, 2, 3, 4, 5 if the instruction at that address is
unknown, a jump, a conditional jump, a call, a return, or an interrupt.
Usage: get_insn_type ADDR
end


define step_to_call
    set $_saved_ctx = $SHOW_CONTEXT
    set $SHOW_CONTEXT = 0
    set $SHOW_NEST_INSN = 0
 
    set logging file /dev/null
    set logging redirect on
    set logging on
 
    set $_cont = 1
    while ($_cont > 0)
        stepi
        get_insn_type $pc
        if ($INSN_TYPE == 3)
            set $_cont = 0
        end
    end

    set logging off

    if ($_saved_ctx > 0)
        context
    end

    set $SHOW_CONTEXT = $_saved_ctx
    set $SHOW_NEST_INSN = 0
 
    set logging file ~/gdb.txt
    set logging redirect off
    set logging on
 
    printf "step_to_call command stopped at:\n  "
    x/i $pc
    printf "\n"
    set logging off

end
document step_to_call
Single step until a call instruction is found.
Stop before the call is taken.
Log is written into the file ~/gdb.txt.
end


define trace_calls

    printf "Tracing...please wait...\n"

    set $_saved_ctx = $SHOW_CONTEXT
    set $SHOW_CONTEXT = 0
    set $SHOW_NEST_INSN = 0
    set $_nest = 1
    set listsize 0
  
    set logging overwrite on
    set logging file ~/gdb_trace_calls.txt
    set logging on
    set logging off
    set logging overwrite off

    while ($_nest > 0)
        get_insn_type $pc
        # handle nesting
        if ($INSN_TYPE == 3)
            set $_nest = $_nest + 1
        else
            if ($INSN_TYPE == 4)
                set $_nest = $_nest - 1
            end
        end
        # if a call, print it
        if ($INSN_TYPE == 3)
            set logging file ~/gdb_trace_calls.txt
            set logging redirect off
            set logging on

            set $x = $_nest - 2
            while ($x > 0)
                printf "\t"
                set $x = $x - 1
            end
            x/i $pc
        end

        set logging off
        set logging file /dev/null
        set logging redirect on
        set logging on
        stepi
        set logging redirect off
        set logging off
    end

    set $SHOW_CONTEXT = $_saved_ctx
    set $SHOW_NEST_INSN = 0
 
    printf "Done, check ~/gdb_trace_calls.txt\n"
end
document trace_calls
Create a runtime trace of the calls made by target.
Log overwrites(!) the file ~/gdb_trace_calls.txt.
end


define trace_run
 
    printf "Tracing...please wait...\n"

    set $_saved_ctx = $SHOW_CONTEXT
    set $SHOW_CONTEXT = 0
    set $SHOW_NEST_INSN = 1
    set logging overwrite on
    set logging file ~/gdb_trace_run.txt
    set logging redirect on
    set logging on
    set $_nest = 1

    while ( $_nest > 0 )

        get_insn_type $pc
        # jmp, jcc, or cll
        if ($INSN_TYPE == 3)
            set $_nest = $_nest + 1
        else
            # ret
            if ($INSN_TYPE == 4)
                set $_nest = $_nest - 1
            end
        end
        stepi
    end

    printf "\n"

    set $SHOW_CONTEXT = $_saved_ctx
    set $SHOW_NEST_INSN = 0
    set logging redirect off
    set logging off

    # clean up trace file
    shell  grep -v ' at ' ~/gdb_trace_run.txt > ~/gdb_trace_run.1
    shell  grep -v ' in ' ~/gdb_trace_run.1 > ~/gdb_trace_run.txt
    shell  rm -f ~/gdb_trace_run.1
    printf "Done, check ~/gdb_trace_run.txt\n"
end
document trace_run
Create a runtime trace of target.
Log overwrites(!) the file ~/gdb_trace_run.txt.
end




# ____________________misc____________________
define hook-stop

    # this makes 'context' be called at every BP/step
    if ($SHOW_CONTEXT > 0)
        context
    end
    if ($SHOW_NEST_INSN > 0)
        set $x = $_nest
        while ($x > 0)
            printf "\t"
            set $x = $x - 1
        end
    end
end
document hook-stop
!!! FOR INTERNAL USE ONLY - DO NOT CALL !!!
end

define assemble
    printf "\nType code to assemble and hit Ctrl-D when finished.\n"
    printf "You must use NASM (Intel) syntax.\n"
    printf "It is recommended to start with: BITS 32\n"

    shell filename=$(mktemp); \
          binfilename=$(mktemp); \
          echo -e "Writing into: ${filename}\n"; \
          cat > $filename; echo ""; \
          nasm -f elf -o $binfilename $filename; \
          objdump -M intel -d -j .text $binfilename; \
          rm -f $binfilename; \
          rm -f $filename; \
          echo -e "temporaly files deleted.\n"
end
document assemble
Assemble instructions to binary opcodes. Uses nasm and objdump.
Usage: assemble
end


define assemble_gas
    printf "\nType code to assemble and hit Ctrl-D when finished.\n"
    printf "You must use GNU assembler (AT&T) syntax.\n"

    shell filename=$(mktemp); \
          binfilename=$(mktemp); \
          echo -e "Writing into: ${filename}\n"; \
          cat > $filename; echo ""; \
          as -o $binfilename < $filename; \
          objdump -d -j .text $binfilename; \
          rm -f $binfilename; \
          rm -f $filename; \
          echo -e "temporaly files deleted.\n"
end
document assemble_gas
Assemble instructions to binary opcodes. Uses GNU as and objdump.
Usage: assemble_gas
end


define dump_hexfile
    dump ihex memory $arg0 $arg1 $arg2
end
document dump_hexfile
Write a range of memory to a file in Intel ihex (hexdump) format.
The range is specified by ADDR1 and ADDR2 addresses.
Usage: dump_hexfile FILENAME ADDR1 ADDR2
end


define dump_binfile
    dump memory $arg0 $arg1 $arg2
end
document dump_binfile
Write a range of memory to a binary file.
The range is specified by ADDR1 and ADDR2 addresses.
Usage: dump_binfile FILENAME ADDR1 ADDR2
end


define cls
    shell clear
end
document cls
Clear screen.
end




# _________________user tips_________________
# The 'tips' command is used to provide tutorial-like info to the user
define tips
    printf "Tip Topic Commands:\n"
    printf "\ttip_display : Automatically display values on each break\n"
    printf "\ttip_patch   : Patching binaries\n"
    printf "\ttip_strip   : Dealing with stripped binaries\n"
    printf "\ttip_syntax  : AT&T vs Intel syntax\n"
end
document tips
Provide a list of tips from users on various topics.
end


define tip_patch
    printf "\n"
    printf "                   PATCHING MEMORY\n"
    printf "Any address can be patched using the 'set' command:\n"
    printf "\t`set ADDR = VALUE` \te.g. `set *0x8049D6E = 0x90`\n"
    printf "\n"
    printf "                 PATCHING BINARY FILES\n"
    printf "Use `set write` in order to patch the target executable\n"
    printf "directly, instead of just patching memory\n"
    printf "\t`set write on` \t`set write off`\n"
    printf "Note that this means any patches to the code or data segments\n"
    printf "will be written to the executable file\n"
    printf "When either of these commands has been issued,\n"
    printf "the file must be reloaded.\n"
    printf "\n"
end
document tip_patch
Tips on patching memory and binary files.
end


define tip_strip
    printf "\n"
    printf "             STOPPING BINARIES AT ENTRY POINT\n"
    printf "Stripped binaries have no symbols, and are therefore tough to\n"
    printf "start automatically. To debug a stripped binary, use\n"
    printf "\tinfo file\n"
    printf "to get the entry point of the file\n"
    printf "The first few lines of output will look like this:\n"
    printf "\tSymbols from '/tmp/a.out'\n"
    printf "\tLocal exec file:\n"
    printf "\t        `/tmp/a.out', file type elf32-i386.\n"
    printf "\t        Entry point: 0x80482e0\n"
    printf "Use this entry point to set an entry point:\n"
    printf "\t`tbreak *0x80482e0`\n"
    printf "The breakpoint will delete itself after the program stops as\n"
    printf "the entry point\n"
    printf "\n"
end
document tip_strip
Tips on dealing with stripped binaries.
end


define tip_syntax
    printf "\n"
    printf "\t    INTEL SYNTAX                        AT&T SYNTAX\n"
    printf "\tmnemonic dest, src, imm            mnemonic src, dest, imm\n" 
    printf "\t[base+index*scale+disp]            disp(base, index, scale)\n"
    printf "\tregister:      eax                 register:      %%eax\n"
    printf "\timmediate:     0xFF                immediate:     $0xFF\n"
    printf "\tdereference:   [addr]              dereference:   addr(,1)\n"
    printf "\tabsolute addr: addr                absolute addr: *addr\n"
    printf "\tbyte insn:     mov byte ptr        byte insn:     movb\n"
    printf "\tword insn:     mov word ptr        word insn:     movw\n"
    printf "\tdword insn:    mov dword ptr       dword insn:    movd\n"
    printf "\tfar call:      call far            far call:      lcall\n"
    printf "\tfar jump:      jmp far             far jump:      ljmp\n"
    printf "\n"
    printf "Note that order of operands in reversed, and that AT&T syntax\n"
    printf "requires that all instructions referencing memory operands \n"
    printf "use an operand size suffix (b, w, d, q)\n"
    printf "\n"
end
document tip_syntax
Summary of Intel and AT&T syntax differences.
end


define tip_display
    printf "\n"
    printf "Any expression can be set to automatically be displayed every time\n"
    printf "the target stops. The commands for this are:\n"
    printf "\t`display expr'     : automatically display expression 'expr'\n"
    printf "\t`display'          : show all displayed expressions\n"
    printf "\t`undisplay num'    : turn off autodisplay for expression # 'num'\n"
    printf "Examples:\n"
    printf "\t`display/x *(int *)$esp`      : print top of stack\n"
    printf "\t`display/x *(int *)($ebp+8)`  : print first parameter\n"
    printf "\t`display (char *)$esi`        : print source string\n"
    printf "\t`display (char *)$edi`        : print destination string\n"
    printf "\n"
end
document tip_display
Tips on automatically displaying values when a program stops.
end




# __________________gdb options_________________


set confirm off
set verbose off
set prompt \033[01;31mgdb$ \033[0m

set output-radix 0x10
set input-radix 0x10

# These make gdb never pause in its output
set height 0
set width 0

# Display instructions in Intel format
set disassembly-flavor intel

set $SHOW_CONTEXT = 1
set $SHOW_NEST_INSN = 0

set $CONTEXTSIZE_STACK = 6
set $CONTEXTSIZE_DATA  = 8
set $CONTEXTSIZE_CODE  = 10


#EOF

