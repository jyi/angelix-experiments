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
    seqMatch = SequenceMatcher(None, expected, actual)
    match += seqMatch.find_longest_match(0, len(expected), 0, len(actual)).size    

cost = len(actual) - match

if "Stack dump:" in actual:
    if os.getenv('ANGELIX_ERROR_COST') is not None:
        cost += int(os.getenv('ANGELIX_ERROR_COST'))

print('cost: {}'.format(cost))

cost_file = os.getenv('ANGELIX_COST_FILE')
if cost_file is not None:
    with open(cost_file, "w") as f:
        f.write(str(cost))
