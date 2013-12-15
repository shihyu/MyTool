import gdb

def read_source_code(filename, target_line, num_lines):
    with open(filename, 'r') as fr:
        target_line -= 1
        lines = ['  | ' + line[:-1] for line in fr]
        lines[target_line] = '->| ' + lines[target_line][4:]
        offset = num_lines / 2
        return lines[target_line - offset : target_line + offset]

class ShorternBacktraceCommand(gdb.Command):
    '''Show a backtrace without argument info in each frame.'''

    def __init__(self):
        super(ShorternBacktraceCommand, self).__init__ ("bt",
                                                        gdb.COMMAND_SUPPORT,
                                                        gdb.COMPLETE_NONE)
    def invoke(self, arg, from_tty):
        # Parse arguments.
        show_source = False
        num = 0;
        args = arg.split()
        for s in args:
            if s == '-s':
                show_source = True
            else:
                try:
                    num = int(s)
                except Exception, e:
                    pass

        # Extract frame info.
        frames = []
        f = gdb.newest_frame()
        fn = 0
        while f is not None:
            symtab_and_line = gdb.Frame.find_sal(f)
            frame_name = gdb.Frame.name(f)
            if frame_name:
                filename = None
                if symtab_and_line.symtab:
                    filename = symtab_and_line.symtab.filename
                outs = (
                    fn,
                    frame_name,
                    filename if filename else '??',
                    symtab_and_line.line,
                )
            else:
                outs = (fn, '??', 'unknown', 0)
            head = '#%-2d  %s at %s:%s' % outs
            codes = None
            if show_source and frame_name and filename:
                codes = read_source_code(symtab_and_line.symtab.fullname(),
                                         symtab_and_line.line,
                                         10)
            frames.append((head, codes))
            f = gdb.Frame.older(f)
            fn += 1

        # Hold the subset.
        if num > 0:
            frames = frames[:num]
        elif num < 0:
            frames = frames[len(frames) + num:]

        # Print the result.
        for head, codes in frames:
            print head
            if codes:
                for line in codes:
                    print line
                print


ShorternBacktraceCommand()
