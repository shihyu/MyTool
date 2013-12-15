import gdb
import re
class ShorternBacktraceCommand(gdb.Command):
    '''Show a backtrace without argument info in each frame.'''

    def __init__(self):
        super(ShorternBacktraceCommand, self).__init__ ("bt",
                                                        gdb.COMMAND_SUPPORT,
                                                        gdb.COMPLETE_NONE)
    def invoke(self, arg, from_tty):
        if not arg:
            arg = ''
        raw = gdb.execute("backtrace %s" % arg, True, True)
        print '#-----'
        print raw
        print '#-----'
        lines = raw.split('\n')
        print '#-----'
        print lines
        print '#-----'
        for i, line in enumerate(lines):
            if not line:
                continue

            tokens = line.split()
            print '<%s>' % line
            print '??'
            print len(tokens)
            print '??'
            # first line format: e.g., #0  A::hello (...) at a.cpp:8
            # the rest         : e.g., #2  0x0..0 in A::foo (...) at a.cpp:18
            func_index = 1 if i == 0 else 3
            print ('\033[1;33m%2s\033[m  %s at %s'
                   '' % (tokens[0], tokens[func_index], tokens[-1]))

ShorternBacktraceCommand()
