import logging
import numpy as np
import re
import argparse
from os.path import isfile

logger = logging.getLogger('dist_tiff')


def readData(fname):
    def readLevel2(txt):
        def readLevel3(txt):
            txt = txt.replace('\n','').strip()
            txt_array = txt.split(' ')
            num_array = list(map(lambda t: int(t, 16),
                                 txt_array))
            return num_array

        tiff_strips = list(filter(None, re.split("Strip [0-9]+:", txt)))[1:]
        tiff_strips = list(map(lambda x: readLevel3(x.strip()),
                                      tiff_strips))

        return tiff_strips

    raw_txt = open(fname).read().strip()
    tiff_dirs = list(filter(None, re.split(r"TIFF Directory at .*\n", raw_txt)))

    data_l1 = list(map(lambda x: readLevel2(x),
                       tiff_dirs))

    return data_l1


def normalize(data_l1):
    logger.info("data_l1:\n{}".format(data_l1))

    def rowSize(lst):
        # print("lst:\n{}\n{}".format(lst, len(lst)))
        return len(lst)

    def colSize(lst_l1):
        # print("len(lst_l1): {}".format(len(lst_l1)))

        def colSizeLevel2(lst_l2):
            # print("lst_l2:\n{}\n{}".format(lst_l2, len(lst_l2)))
            # print("len(lst_l2): {}".format(len(lst_l2)))
            return len(lst_l2)

        return max(map(colSizeLevel2, lst_l1))

    logger.info("len(data_l1): {}".format(len(data_l1)))
    max_r = max(map(rowSize, data_l1), default=0)
    max_c = max(map(colSize, [x for x in data_l1 if x != []]), default=0)

    logger.info("max_r: {}".format(max_r))
    logger.info("max_c: {}".format(max_c))

    def normalizeLevel2(data_l2):
        def extCol(data_l2):
            def extColLevel3(data_l3):
                # print("data_l3:\n{}".format(data_l3))
                if len(data_l3) < max_c:
                    return np.hstack((np.asarray(data_l3),
                                      np.zeros((max_c - len(data_l3),),
                                               dtype=int)))
                else:
                    return np.asarray(data_l3)

            return np.asarray(list(map(extColLevel3, data_l2)))

        def extRow(data):
            # print("data:\n{}\n{}".format(data, data.shape))
            if len(data) == 0:
                return np.zeros((max_r, max_c), dtype=int)
            elif len(data) < max_r:
                return np.vstack((data,
                                  np.zeros((max_r - len(data),
                                            data.shape[1]), dtype=int)))
            else:
                return data

        return extRow(extCol(data_l2))

    return np.asarray(list(map(normalizeLevel2, data_l1)))


def matchShape(data_A_l1, data_B_l1):
    # print("data_A_l1:\n{}".format(data_A_l1))
    # print(data_A_l1.shape)
    # print("data_B_l1:\n{}".format(data_B_l1))
    # print(data_B_l1.shape)

    if len(data_A_l1.shape) == len(data_B_l1.shape):
        shape_max = list(map(max, zip(data_A_l1.shape, data_B_l1.shape)))
    elif len(data_A_l1.shape) > len(data_B_l1.shape):
        shape_max = data_A_l1.shape
        data_B_l1 = np.zeros(shape=np.shape(data_A_l1), dtype=int)
    else:
        shape_max = data_B_l1.shape
        data_A_l1 = np.zeros(shape=np.shape(data_B_l1), dtype=int)

    def matchShapeLevel2(data_l2):
        def extend_col(data):
            if data.shape[1] < shape_max[2]:
                return np.hstack((data,
                                  np.zeros((data.shape[0], shape_max[2] - data.shape[1]),
                                           dtype=int)))
            else:
                return data

        def extend_row(data):
            if data.shape[0] < shape_max[1]:
                return np.vstack((data,
                                  np.zeros((shape_max[1] - data.shape[0],
                                            data.shape[1]), dtype=int)))
            else:
                return data

        return extend_row(extend_col(data_l2))

    def ext(array):
        if array.shape[0] < shape_max[0]:
            return np.vstack((array,
                              np.zeros((shape_max[0] - array.shape[0],
                                        array.shape[1],
                                        array.shape[2]), dtype=int)))
        else:
            return array

    new_data_A_l1 = ext(np.asarray(list(map(matchShapeLevel2, data_A_l1))))
    new_data_B_l1 = ext(np.asarray(list(map(matchShapeLevel2, data_B_l1))))

    return new_data_A_l1, new_data_B_l1


if __name__ == '__main__':
    parser = argparse.ArgumentParser('dist_tiff')
    parser.add_argument('golden_img', metavar='GOLDEN IMAGE', help='the first image')
    parser.add_argument('target_img', metavar='TARGET IMAGE', help='the second image')
    parser.add_argument('--log', metavar='LOG', default=None,
                        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                        help='set the logging level')
    args = parser.parse_args()

    if args.log is not None:
        log_level = getattr(logging, args.log, None)
        if not isinstance(log_level, int):
            raise ValueError('Invalid log level: %s' % log_level)

        rootLogger = logging.getLogger()
        rootLogger.setLevel(log_level)
        FORMAT = logging.Formatter('%(levelname)-8s %(name)-15s %(message)s')
        consoleHandler = logging.StreamHandler()
        consoleHandler.setFormatter(FORMAT)
        rootLogger.addHandler(consoleHandler)

    logger.info("golden_img: {}".format(args.golden_img))
    logger.info("target_img: {}".format(args.target_img))

    tiff_data_A = normalize(readData(args.golden_img))
    if isfile(args.target_img):
        tiff_data_B = normalize(readData(args.target_img))
    else:
        logger.info("no existing target img: {}".format(args.target_img))
        tiff_data_B = np.zeros(shape=np.shape(tiff_data_A), dtype=int)

    logger.info("tiff_data_A:\n{}".format(tiff_data_A))
    logger.info("tiff_data_B:\n{}".format(tiff_data_B))

    new_tiff_data_A, new_tiff_data_B = matchShape(tiff_data_A, tiff_data_B)

    logger.info("new_tiff_data_A:\n{}\n{}".format(new_tiff_data_A, new_tiff_data_A.shape))
    logger.info("new_tiff_data_B:\n{}\n{}".format(new_tiff_data_B, new_tiff_data_B.shape))

    dist_array = np.absolute(new_tiff_data_A - new_tiff_data_B)
    logger.info("dist_array:\n {}".format(dist_array))

    dist = np.sum(list(map(lambda array: np.sum(array),
                           dist_array)))

    print("{}".format(dist))
