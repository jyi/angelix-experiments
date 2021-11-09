## Running an experimental script ##

To generate a repair, execute `experiment-<subject> <session ID>` as the following example:

    ./experiment-libtiff 1

The following is the list of subjects we tested:

- libtiff
- php
- gzip
- gmp
- whireshark


To specify the versions, open the `experiment-<subject>` file and modify the following line:


```bash
versions=( "2009-02-05-764dbba-2e42d63" )
```

A list of tested versions is available in `options-guided.json`.

The `experiment-<subject>` also contains the following line to choose an execution mode between "guided" (FAngelix) and "symbolic" (Angelix).

```bash
strategies=( "guided" )
# strategies=( "symbolic" )
```   


Lastly, the following line can be configured to choose defect classes:

```bash
defects=( "if-conditions" "loop-conditions" )
# defects=( "assignments" )
```   

## Experimental results ##

Experimental results are avialble in the [results](https://github.com/jyi/fangelix-experiments/tree/master/results) directory.
