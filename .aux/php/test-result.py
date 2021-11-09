#!/usr/bin/env python3

import logging
import os
from os.path import join
import subprocess
import json


logger = logging.getLogger('test-result')


if __name__ == "__main__":
    rootLogger = logging.getLogger()
    FORMAT = logging.Formatter('%(levelname)-8s %(name)-15s %(message)s')
    rootLogger.setLevel(logging.DEBUG)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(FORMAT)
    rootLogger.addHandler(consoleHandler)

    php_dir = os.path.join(os.getcwd(), 'php')
    num_of_tests = int(subprocess.check_output('../php-run-tests length T',
                                               cwd=php_dir,
                                               encoding='ascii',
                                               shell=True))
    logger.debug('num_of_tests: {}'.format(num_of_tests))

    result_dict = dict()
    pos_list = []
    net_list = []
    for idx in range(1, num_of_tests + 1):
        try:
            result = subprocess.check_output('../php-run-tests {} T'.format(idx),
                                             cwd=php_dir,
                                             encoding='ascii',
                                             stderr=subprocess.STDOUT,
                                             shell=True)
        except subprocess.CalledProcessError as e:
            result = e.output
        if 'PASS' in result:
            logger.debug('test {} passed'.format(idx))
            pos_list.append(idx)
        if 'FAIL' in result:
            logger.debug('test {} failed'.format(idx))
            net_list.append(idx)

    result_dict.update({'pos': pos_list})
    result_dict.update({'neg': net_list})

    with open('test_result.json', 'w') as f:
        f.write(json.dumps(result_dict))
