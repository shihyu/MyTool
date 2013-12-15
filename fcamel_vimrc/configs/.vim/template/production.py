#!/usr/bin/env python
# -*- encoding: utf8 -*-

import sys
import optparse

def main():
    '''\
    %prog [options]
    '''
    parser = optparse.OptionParser(usage=main.__doc__)
    options, args = parser.parse_args()

    if len(args) != 0:
        parser.print_help()
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
