#!/usr/bin/env python3

import logging
import os
from os.path import join
import subprocess
import json
import sys


logger = logging.getLogger('test-script-gen')


def diff(first, second):
    second = set(second)
    return [item for item in first if item not in second]


if __name__ == "__main__":
    rootLogger = logging.getLogger()
    FORMAT = logging.Formatter('%(levelname)-8s %(name)-15s %(message)s')
    rootLogger.setLevel(logging.DEBUG)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(FORMAT)
    rootLogger.addHandler(consoleHandler)

    with open(sys.argv[1]) as f:
        buggy = json.load(f)

    with open(sys.argv[2]) as f:
        fixed = json.load(f)

    logger.debug('buggy: {}'.format(buggy))
    logger.debug('fixed: {}'.format(fixed))

    pos = fixed['pos']
    neg = [item for item in buggy['neg'] if item not in fixed['neg']]

    logger.debug('pos: {}'.format(pos))
    logger.debug('neg: {}'.format(neg))

    with open('test.sh', 'w') as f:
        f.write('#!/bin/bash\n\n')
        f.write('if [ `basename $2` = "coverage" ] ; then\n')
        f.write('    cov=0\n')
        f.write('else\n')
        f.write('    cov=1\n')
        f.write('fi\n\n')
        f.write('run_test() {\n')
        f.write('    cd php\n')
        f.write('    /root/mountpoint-genprog/genprog-many-bugs/php-bug-2011-05-24-b60f6774dc-1056c57fa9/limit /root/mountpoint-genprog/genprog-many-bugs/php-bug-2011-05-24-b60f6774dc-1056c57fa9/php-run-tests $1 T\n')
        f.write('    RESULT=$?')
        f.write('    cd ..')
        f.write('case $1 in\n')
        f.write('    return $RESULT\n')
        f.write('}\n')
        f.write('case $1 in\n')
        for i, test in enumerate(sorted(pos)):
            f.write('    p{}) run_test {} && exit 0 ;;\n'.format(i, test))
        for i, test in enumerate(sorted(neg)):
            f.write('    n{}) run_test {} && exit 0 ;;\n'.format(i, test))
        f.write('esac\n')
        f.write('exit 1\n')
