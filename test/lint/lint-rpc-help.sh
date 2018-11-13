#!/usr/bin/env bash
#
# Copyright (c) 2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C

EXIT_CODE=0
non_autogenerated_help=$(grep --perl-regexp --null-data --only-matching 'runtime_error\(\n\s*".*\\n"\n' $(git ls-files -- "*.cpp"))
if [[ ${non_autogenerated_help} != "" ]]; then
    echo "Must use RPCHelpMan to generate the help for the following RPC methods:"
    echo "${non_autogenerated_help}"
    echo
    EXIT_CODE=1
fi
exit ${EXIT_CODE}
