yaml-ditto
==========

Consider the following yaml file:

"""Yaml
web:
  RSS: Really Simple Syndication
  RSS: Rich Site Summary
hw:
  RSS: Resident Set Size
"""

When serializing this file, for example to a hash structure in Ruby, the key-value pair on line two is silently overwritten by the pair on the next line, which is expected behavior. This script helps to detect such duplicates in yaml files, so that you can modify the files accordingly. It can also detect duplicate keys that do not get overwritten (last line in above example). You can also use it to search for repeated keys in multiple yaml files.

View the help by running:

    ./yaml-ditto.sh -h

To list duplicate keys that would be overwritten together with the number of occurrences, pass the yaml to the script. For example:

    ./yaml-ditto.sh testfile.yaml

To do the same for multiple files, use the -m switch. For example:

    ./yaml-ditto.sh -m *.yaml

To list all duplicate keys (both valid and invalid) execute:

    ./yaml-ditto.sh -a testfile.yaml

To find if keys of a yaml file are also present in other files, use the -c switch. For example:

    ./yaml-ditto.sh -c testfile1.yaml *.yaml

The first file passed to -c is compared to files that follow.
