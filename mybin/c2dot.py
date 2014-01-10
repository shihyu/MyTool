#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys

global cflow
global dot
cflow = '/usr/bin/cflow'
dot   = '/usr/bin/dot'

if os.path.isfile(cflow):
    pass
else:
    print('cflow is not installed!')
    sys.exit(0)

if os.path.isfile(dot):
    pass
else:
    print('dot is not installed!')
    sys.exit(0)

global color
global shape
color = ['#eecc80', '#ccee80', '#80ccee', '#eecc80', '#80eecc']
shape = ['box', 'ellipse', 'octagon', 'hexagon', 'diamond']


global version
version = '20130523'


def get_max_space(lines):
    space = 0
    for i in range(0, len(lines)):
        if lines[i].startswith(space * 4 * ' '):
            i = 0
            space += 1
    return space


def get_name(line):
    name = ''
    for i in range(0, len(line)):
        if line[i] == ' ':
            pass
        elif line[i] == '(':
            break
        else:
            name += line[i]
    return name


def parse(data, offset = 0, filename = ''):
    global color
    global shape
    dot = ''
    dot += 'digraph G {\n'
    dot += 'node [peripheries=2 style="filled,rounded" fontname="Vera Sans Mono" color="#eecc80"];\n'
    dot += 'rankdir=LR;\n'
    dot += 'label="%s"\n' % filename
    dot += 'main [shape=box];\n'
    lines = data.replace('\r', '').split('\n')
    max_space = get_max_space(lines)
    for i in range(0, max_space):
        for j in range(0, len(lines)):
            if lines[j].startswith((i + 1) * 4 * ' ') and not lines[j].startswith((i + 2) * 4 * ' '):
                sub_node = get_name(lines[j])
                dot += (('node [color="%s" shape=%s];edge [color="%s"];\n') % (
                        color[i % 5], shape[i % 5], color[i % 5]))
                dot += (node + '->' + sub_node + '\n')
            elif lines[j].startswith(i * 4 * ' '):
                node = get_name(lines[j])
        
    dot += '}\n'
    return dot

def usage():
    doc = '''cflow2dot.py file1 file2 ..... --output[-o] outputfilename
(output file format is svg)
--version (-v) show version
--help (-h) show this document'''
    print(doc)

def get_input_file():
    input_filename = ''
    argv = sys.argv
    for i in range(1, len(argv)):
        if argv[i] == '-o' or argv[i] == '--output':
            break
        else:
            input_filename += (argv[i] + ' ')
    return input_filename

def get_output_file():
    argv = sys.argv
    if argv[len(argv) - 2] == '-o' or argv[len(argv) - 2] == '--output':
        output_file = os.path.join(os.getcwd(), argv[len(argv) - 1])
    else:
        output_file = os.path.join(os.getcwd(), 'a.svg')
    return output_file
    



def main():
    global dot
    global cflow    
    input_filename = ''
    if len(sys.argv) == 2:
        input_filename = sys.argv[1]
    else:
        input_filename = get_input_file()
    command = cflow + ' ' + input_filename
    output_file = get_output_file()
    cflow_data = os.popen(command).read()
    dotdata = parse(cflow_data)
    try:
        with open(os.path.join(output_file, output_file + '.dot'), 'w') as fp:
            fp.write(dotdata)
        command = 'dot -Tsvg %s' % os.path.join(output_file + '.dot')
        svg_data = os.popen(command).read()
        with open(output_file, 'w') as fp:
            fp.write(svg_data)
    except Exception as e:
        print(e)


if __name__ == "__main__":
    main()

