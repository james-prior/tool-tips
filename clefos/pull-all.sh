#!/bin/sh 
#	debugging: -x
#
#	pull-all.sh
#		$Id: pull-all.sh,v 1.15 2014/06/25 18:51:36 herrold Exp herrold $
#	Copyright (c) 2014 R P Herrold info@owlriver.com
#	lives on: centos-6 at: /home/herrold/vcs/git/centos-7-archive
#	outside will be in: https://github.com/herrold/tool-tips/tree/master/clefos
#	reports to: info@owlriver.com
#	discussion: http://lists.clefos.org/mailman/listinfo, on list:
#		e7-devel-list
#       license: GPLv3+
#
#	based on our practice approach at: 
#		http://wiki.centos.org/Sources
#	at 2014 06 11
#
#	you almost certainly will need to elide or 
#	conform the YAK stanza to YOUR approach
#
#	run thus:
#		# (optionally, to clear the log) > buildlog-name.txt
#		time ./pull-all.sh | tee -a buildlog-name.txt
#
PATH='/bin:/usr/bin:/usr/sbin:/sbin:~/bin/'
MYNAME=`basename $0`
#
#	only start at and following this package.  We make SRPMs alpha
#	absent a reason to prefer one order over another
SKIPTIL=""
#
#	you will want to amend this
DIST=".CHANGEME"
#
DEBUG=""
#
#	made by: git-C-manifest.sh, and stats-close.sh
#	from: https://github.com/herrold/tool-tips/tree/master/clefos
EROOT="/home/herrold/clefos"
EFILE="c7-packages.txt"
ECACHE="c7-SRPM-cache.txt"
EBLOCKFILE="c7-blockfile.txt"
#
#	from the C wiki page cited
ANCHORDIR="/home/herrold/vcs/git/centos-7-archive"
PULLSCRIPT="centos-git-common/get_sources.sh"
#
#	no twitter 
#	this will not work unless you configure it properly
NOTWITTER="y"
#
#################################################3
#	main body follows
cd
cd ${ANCHORDIR}
#
#	update the pullscript -- lots of changes upstream 
#	happening so this may break
PSD=` echo "${PULLSCRIPT}" | tr '/' ' ' | awk {'print $1'} `
[ -e ${PSD} ] && {
	cd ${PSD}
	git pull
	cd ..
	}
#
#	SKIPTIL will move into an argument, but for now is hard coded
#	if present, we are DELAYED building until we see it 
[ "x${SKIPTIL}" != "x" ] && {
	export DELAYED="y"
	}
#
#	we walk all remote git package names in turn
#	this driver list is sorted alpha
for i in ` awk {'print $1'} ${EROOT}/${EFILE} ` ; do
#
export OMIT=""
[ "x${SKIPTIL}" = "x$i" ] && {
	export DELAYED=""
	}
#
	cd ${ANCHORDIR}
#
# FIXME: These are being left in the TLD in some error cases -- why?
# rm -rf BUILD BUILDROOT RPMS SOURCES SPECS SRPMS
#
#	when we started developing we simplified the main loop
# for i in 389-ds-base ; do
	echo "$i"
	echo "${MYNAME}: considering: $i" | logger -p local1.info
#
#	we keep a local blocklist of packages which we over-ride
	export BLOCKED=""
	[ -e ${EROOT}/${EBLOCKFILE} ] && {
	for j in `cat ${EROOT}/${EBLOCKFILE}` ; do
		[ "x$i" = "x$j" ] && {
			export BLOCKED="y"
			echo "info: blocked for $j " 1>&2
			}
	done
	}
#
#	if we were NEITHER blocked, or delayed, proceed
	[ "x${BLOCKED}" = "x" -a "x${DELAYED}" = "x" ] && {
#
# TBD: make this the -f option
#		--freshen
#	[ -e $i   ] && rm -rf $i
	[ ! -d $i ] && 
		git clone  https://git.centos.org/git/rpms/$i.git 
#
#	we do a SRPM check here to remove the former Hendrix conditional
#
#	test emit a SRPM only, if we do not already have one
	CNT=0
#	check the cache
	[ -s ${EROOT}/${ECACHE} ] && \
		CNT=`grep -c "${i}-[0-9]*.src.rpm" ${EROOT}/${ECACHE} `
#	if we have a cache miss, we may still have a later build
	[ 0$CNT -lt 1 ] && {
		[ -e ./$i ] && \
		CNT=`find ./$i -name "${i}-[0-9]*.src.rpm" | grep -c "src.rpm$"`
		}
	[ 0$CNT -gt 0 ] && {
		export OMIT="y"
		}
	[ "x${OMIT}" = "x"  -a "x${DEBUG}" != "x" ] && {
		 [ -e ./$i ] && {
			FOUND=` find ./$i -name "${i}-[0-9]*.src.rpm" | head -n 1 `
			echo "${MYNAME}: found: ${FOUND}" | logger -p local1.info
			}
		}
#
#	the following test is: while we have the directory, but no matching SRPM
#	so retrieve the git sources, etc, so we may try to build one
	cd ${ANCHORDIR}
#	this just for doing a CO
	[ "x${OMIT}" = "x" ] && {
	[ -e $i   -a  0$CNT -lt 1 ] && {
	cd $i
	git checkout c7
#
#	prolly surplussage as we are not amending content here
	git branch my-$i
	${ANCHORDIR}/${PULLSCRIPT}
	cd ..
		}
#	bottom of the just for doing a CO
		}
#
#	SHOULD we proceed?
[ "x${OMIT}" = "x" ] && {
#	CAN we proceed?
	cd ${ANCHORDIR}
	[ -e ./$i   ] && {
	cd $i
#
	[ "x${DEBUG}" != "x" ] && {
#	out of scope for production needs
		git branch
		echo "after git CO" 1>&2
		echo -n "info: PWD 1: " 1>&2
		pwd 1>&2
		}
#
#	remembering Jimi ...
[ "x6" = "x9" ] && {
#
#	RPH local practice -- we use a different approach on SOURCES location
#
#	in ~/.rpmmacros/ 
#		%_sourcedir	%{_topdir}/SOURCES/%{name}
#	for ancient historical reasons out of scope here
#
	echo -n "info: view a local option _sourcedir: " 1>&2
#
#	fragments for editting purposes
#	--define "%_topdir `pwd`" --define "%name $i"
#
	rpmbuild --showrc | grep "_sourcedir" | awk {'print $2" "$3'} 1>&2
	SRCPATH=`rpmbuild --showrc | grep "_sourcedir" | awk {'print $3'} | \
		head -n 1`
	echo "info: SRCPATH: ${SRCPATH} " 1>&2
	echo "info: SOURCES/i: SOURCES/$i " 1>&2
	echo "notice: compare above -- may need dirname normalization" 1>&2
# exit 1
	}
#
#	RPH local practice -- fixup of SOURCES on a per package basis
#	as before for %_sourcedir
	[ "x${DEBUG}" != "x" ] && {
		echo -n "info: PWD 2: " 1>&2
		pwd 1>&2
		}
#
#	if your %_sourcedir does not match ours, this is probably
#	in need of amendment or omission
	[ -e ./SOURCES/ -a ! -e ./SOURCES/$i ] && {
		mv SOURCES YAK
		mkdir -p ./SOURCES/$i/
		rsync -a YAK/. ./SOURCES/$i/.
		rm -rf YAK
		}
#
#	RPH local practice -- remaining suspect paths check
#	as before for %_sourcedir
## 	[ "x${DEBUG}" != "x" ] && {
	echo "info: DIR check" 1>&2
	find . -maxdepth 2 -type d | grep -v "/.git" | \
		grep -v "^.$" | sed -e 's@^./@@g' 1>&2
##		}
#	
#	RPH local practice -- sometimes missing the name fixup
#	possibly an artifact of our: %_sourcedir approach
#	this SHOULD be silent
#	obsolete code
	[ "x6" = "x9" ] && {
#	in a Purple Haze
	echo "info: looking for unexpanded paths" 1>&2
	for j in ` find . -maxdepth 1 -type d | grep -v "/.git" ` ; do
		NEWDIR=` echo "${j}" | sed -e "s@%{name}@$i@"`
		[ "x${j}" != "x${NEWDIR}" ] && {
			mv ${j} ${NEWDIR}
			echo "warning: fixed: $j to be: ${NEWDIR}" 1>&2
			}
	done
		}
#	left behind during debugging
#	exit
#
###############################################################
#	back to code of general import
#
#	emit a SRPM only, if we do not already have one
	CNT=0
#	check the cache
	[ -s ${EROOT}/${ECACHE} ] && \
		CNT=`grep -c "${i}-[0-9]*.src.rpm" ${EROOT}/${ECACHE} `
#	if we have a cache miss, we may still have a later build
#	we are down in the package directory already, so the find path
#	is just the CWD
	[ 0$CNT -lt 1 ] && \
		CNT=`find . -name "${i}-[0-9]*.src.rpm" | grep -c "src.rpm$"`
#	if STILL not present, build it
	[ 0$CNT -lt 1 ] && {
		rpmbuild --nodeps --define "%_topdir `pwd`" \
			--define "%dist ${DIST}" \
			-bs SPECS/$i.spec 
#
#	did it succeed?
#	this is fast, as it is down a level from the top WD in the package
#	directory
#	we don't need a cache here
	CNT=0
	CNT=`find . -name "${i}-[0-9]*.src.rpm" | grep -c "src.rpm$"`
	[ 0$CNT -gt 0 ] && {
		FOUND=` find . -name "${i}-[0-9]*.src.rpm" | head -n 1 `
		echo "${MYNAME}: just made: ${FOUND}" | \
			sed -e "s@ ./@ @g" | \
			logger -p local1.info
#
#	most people will not be doing this
#	if non-null, we do not tweet
	[ "x${NOTWITTER}" = "x" ] && {
#	twitter support
# echo "pre"
		echo "${MYNAME}: just made: ${FOUND}" | \
		sed -e "s@ ./SRPMS/@ @g" | \
	/home/herrold/build/6/ttytter/ttytter-2.1.00.pl \
		-rc=/home/herrold/.ttytter-buildmonbot-rc \
		-keyf=/home/herrold/.ttytter-buildmonbot-key \
		-silent \
		-status=- 
		sleep 30 
		# -silent
# echo "post"
#	bottom of twitter
	}
#
#	and tell the console ...
		echo -n "info: SRPM fruit: " 1>&2
		find . -name "${i}-[0-9]*.src.rpm" | sed -e 's@^./@@g' 1>&2
			}
		}
#
#	and some whitespace to clean out the display
	echo " " 1>&2
#
#	optionally try to build the package from .spec file
#	this has retrieval and build environment overtones, and 
#	is probably a poor idea here, despite the wiki example
#
#	\
#		&& \
#	rpmbuild --define "%_topdir `pwd`" \
#		--define "%dist ${DIST}" \
#		-ba SPECS/$i.spec
#
#	bottom of CAN
		}
#
#	bottom of last OMIT
	}
#
#	belt and suspenders checking
	cd ${ANCHORDIR}
	[ ! -e ./$i ] && {
		pwd
		echo "error: cannot see: ${ANCHORDIR}/$i" 1>&2
		echo "${MYNAME}: error: cannot see: ${ANCHORDIR}/$i" | \
			logger -p local1.info
		}
#
#	bottom of BLOCKED / DELAYED packages conditional
	}
	cd ${ANCHORDIR}
#
done
#
