import re
import os
import sys
from difflib import SequenceMatcher


act_out_file = sys.argv[1]

with open(act_out_file, "r") as f:
    actual = f.read()
    # ignore newlines
    actual = re.sub('\n', '', actual)

match = 0
for expected in sys.argv[2:]:
    # print('expected: {}'.format(expected))
    # print('actual: {}'.format(actual))
    seqMatch = SequenceMatcher(None, expected, actual)
    match += seqMatch.find_longest_match(0, len(expected), 0, len(actual)).size

cost = max(len(actual) - match, len(expected) - match)
print(cost)
