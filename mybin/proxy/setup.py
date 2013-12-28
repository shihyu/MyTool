#! /usr/bin/env python
# coding=utf-8
#############################################################################
#                                                                           #
#   File: setup.py                                                          #
#                                                                           #
#   Copyright (C) 2008-2010 Du XiaoGang <dugang.2008@gmail.com>             #
#                                                                           #
#   Home: http://gappproxy.googlecode.com                                   #
#                                                                           #
#   This file is part of GAppProxy.                                         #
#                                                                           #
#   GAppProxy is free software: you can redistribute it and/or modify       #
#   it under the terms of the GNU General Public License as                 #
#   published by the Free Software Foundation, either version 3 of the      #
#   License, or (at your option) any later version.                         #
#                                                                           #
#   GAppProxy is distributed in the hope that it will be useful,            #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#   GNU General Public License for more details.                            #
#                                                                           #
#   You should have received a copy of the GNU General Public License       #
#   along with GAppProxy.  If not, see <http://www.gnu.org/licenses/>.      #
#                                                                           #
#############################################################################

from distutils.core import setup
import py2exe
import glob
import common

setup(
    options = {"py2exe": 
        { "optimize": 2,
          "compressed": 1,
          "bundle_files": 1
        }
    },

    name = "GAppProxy",
    version = common.VERSION,
    description = "HTTP(S) Proxy. 127.0.0.1:8000",

    zipfile = None,
    console=['proxy.py'],
    
    data_files = [
        ('ssl', glob.glob('ssl/*'))
    ]
)
