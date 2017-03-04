#!/bin/sh
# Copyright (c) 2014-2016 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

INPUT=$(cat /dev/stdin)
VALID=false
REVSIG=false
IFS='
'
if [ "$BITCOIN_VERIFY_COMMITS_ALLOW_SHA1" = 1 ]; then
	GPG_RES="$(echo "$INPUT" | gpg --trust-model always "$@" 2>/dev/null)"
else
	# Note how we've disabled SHA1 with the --weak-digest option, disabling
	# signatures - including selfsigs - that use SHA1. While you might think that
	# collision attacks shouldn't be an issue as they'd be an attack on yourself,
	# in fact because what's being signed is a commit object that's
	# semi-deterministically generated by untrusted input (the pull-req) in theory
	# an attacker could construct a pull-req that results in a commit object that
	# they've created a collision for. Not the most likely attack, but preventing
	# it is pretty easy so we do so as a "belt-and-suspenders" measure.

	GPG_RES="$(echo "$INPUT" | gpg --trust-model always --weak-digest sha1 "$@" 2>/dev/null)"
fi
for LINE in $(echo "$GPG_RES"); do
	case "$LINE" in
	"[GNUPG:] VALIDSIG "*)
		while read KEY; do
			[ "${LINE#?GNUPG:? VALIDSIG * * * * * * * * * }" = "$KEY" ] && VALID=true
		done < ./contrib/verify-commits/trusted-keys
		;;
	"[GNUPG:] REVKEYSIG "*)
		[ "$BITCOIN_VERIFY_COMMITS_ALLOW_REVSIG" != 1 ] && exit 1
		while read KEY; do
			case "$LINE" in "[GNUPG:] REVKEYSIG ${KEY#????????????????????????} "*)
				REVSIG=true
				GOODREVSIG="[GNUPG:] GOODSIG ${KEY#????????????????????????} "
			esac
		done < ./contrib/verify-commits/trusted-keys
		;;
	esac
done
if ! $VALID; then
	exit 1
fi
if $VALID && $REVSIG; then
	echo "$INPUT" | gpg --trust-model always "$@" | grep "\[GNUPG:\] \(NEWSIG\|SIG_ID\|VALIDSIG\)" 2>/dev/null
	echo "$GOODREVSIG"
else
	echo "$INPUT" | gpg --trust-model always "$@" 2>/dev/null
fi
