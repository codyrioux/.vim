#!/bin/sh

# Name:        vim7-install.sh
# Summary:     script to install Vim7 from sources.
# Author:      Yakov Lerner
# Date:        2008-02-20
# Url:         http://www.vim.org/scripts/script.php?script_id=1473


USAGE=\
'Description: download, build and install vim7 from svn sources.
    First off, script asks you whether you want to install Vim
    system-wide (you need to know root password for that), or 
    under user'"'"'s $HOME (for one user only).

    Vim will be built and configured with --with-features=huge.
    You can pass configure options on the commandline. All options
    starting with -- are passed to configure. vim7-install.sh --help
    prints list of all options recognized by configure.

Options: 
    any option beginning with -- is passed to configure.
    --help   print list of --options recognized by configure step.
    -svnco     use "svn checkout" download sources. Default method is svnexport
               "svn checkout" is slower than svnexport on first time, but
               faster on repeated (incremental) rebuilds.
    -svnexport [default] use "svn export" to download sources. svnexport is
               faster than svnco on first build, but for repeated builds, svnco
               can be faster,
    -cvs     use cvs method to pull the sources. Default method is svnexport.
             svc servers are sourceforge, they were not always stable in 2005-2006.
             Because of instability of cvs server, default method was set to svn
    -noupdate    skip the source download/update phase
    -noinstall   skip the instllation phase
    -home,-user      install under user'"'"'s $HOME/bin
    -global,-glob    install into /usr/local  (user must be root or know root password)
    -cache DIR   alt. cache dir (defautl is /var/tmp/user$UID
    $VARTMP      base directory for checkout and build. Default is /var/tmp
                 Sources will be in $VARTMP/user$UID/vim7_from_svn/vim7
    -nort        skip downloading of runtime file from rsync server
';


METHODS_LIST="cvs svn svnexport"
DEFAULT_METHOD="svnexport" # default method
DOWNLOAD_METHOD=$DEFAULT_METHOD
LOG=/tmp/`basename $0`.log
prog=`basename $0`
# before 2007-05-09, SVN_URL was https://svn.sourceforge.net/svnroot/vim/vim7
# after  2007-05-09, SVN_URL is  https://vim.svn.sourceforge.net/svnroot/vim/branches/vim7.1 
SVN_URL='https://vim.svn.sourceforge.net/svnroot/vim/trunk'
uid=`perl -e 'use POSIX; print geteuid()'`
CACHE_BASE=${VARTMP:-/var/tmp}/user$uid
RUNTIMES_RSYNC_URL="rsync://ftp.vim.org/Vim/runtime"
# rsync --exclude=dos -n -avz -c rsync://ftp.vim.org/Vim/runtime/. runtime


die() { echo 1>&2 "$*"; exit 100; }


dieUsage() { echo "${USAGE?}"; exit 100; }


NOT() { if "$@"; then return 1; else return 0; fi; }


ASSIGN_DIR() { # -> $DIR, $SRCTOP, $VIMSRC
    case "$DOWNLOAD_METHOD" in 
    "cvs")
        DIR=$CACHE_BASE/vim7-from-cvs
        SRCTOP=$DIR/vim7    # $SRCTOP is used by patching
        VIMSRC=$SRCTOP/src  # $VIMSRC is used by patching
      ;;
    "svn")
        DIR=$CACHE_BASE/vim7-svncheckout
        SRCTOP=$DIR/vim7    # $SRCTOP is used by patching
        VIMSRC=$SRCTOP/src  # $VIMSRC is used by patching
     ;;
    "svnexport")
        DIR=$CACHE_BASE/vim7-svnexport
        SRCTOP=$DIR/vim7    # $SRCTOP is used by patching
        VIMSRC=$SRCTOP/src  # $VIMSRC is used by patching
     ;;
    *)
        die "Error, unknown download method ($DOWNLOAD_METHOD), must be 'svn' or 'svnexport' or 'cvs'"
    esac
    mkdir -p $DIR || die "ERROR creating directory"
    BLD=$DIR/vim7
}


LOG() {
    echo "$@" >>${LOG?}
}


CLEAN_ALL() {
    for method in $METHODS_LIST; do
        DOWNLOAD_METHOD=$method
        ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
        echo "    * cleaning ${DIR?} ..."
        case ${DIR?} in */tmp/*) 
            rm -rf ${DIR?}
        esac
    done
}

CONFIG_HELP() {
    echo '------------------------------------------------------------'
    echo `basename $0` help:
    echo '------------------------------------------------------------'
    echo "$USAGE";
    echo ""

    ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC

    if test ! -f $BLD/configure ; then
        # 'svn co' does not let us check out single file.
        # another possibility is to 'svn co -N' (flat)
        # I tried 'svn co -N' (DO_SVN -N) and it still feels slow.

        STORED_CONFIGURE_HELP_COPY
    else
        echo '------------------------------------------------------------'
        echo 'configure help'
        echo '------------------------------------------------------------'
        ( cd $BLD && ./configure --help )
    fi
    exit
}

DO_CVS() {
    type cvs >/dev/null 2>&1 || { \
        die "ERROR: 'cvs' utility is not installed. Please install and retry";
    }
    if test -d $DIR/vim7/CVS ; then
        echo "# previously downloaded source found."
        sleep 1
        cd $DIR/vim7 || exit 1
        ( set -x; cvs -z3 update )
    else
        mkdir -p $DIR || exit 1
        cd $DIR || exit 1
        ( set -x; cvs -z3 -d:pserver:anonymous@vim.cvs.sf.net:/cvsroot/vim checkout vim7 )
    fi
    if test $? != 0; then
        echo "CVS returned error(s). Press Enter to continue, Ctrl-C to stop"
        read ANSWER
    fi

    DOWNLOAD_RUNTIME_FILES
}

DOWNLOAD_RUNTIME_FILES() { # $DIR
    echo "---"
    if test "$NO_RUNTIME_DOWNLOAD" = 1; then
        echo "    * skipping runtime downloading"
        return
    fi
    if type rsync >/dev/null 2>&1 ; then
        echo "    * Downloading \"runtime files\" using rsync"
        to=$DIR/vim7/runtime/.
        if (set -x; rsync $RSYNC_OPT --exclude=dos -avz -c ${RUNTIMES_RSYNC_URL?}/.  $to ) ; then
            echo "ok, rsync completed"
	else
            echo 1>&2 "Error during rsync. Press Enter to continue"
            read ANS
        fi
    else
        echo "Warning: missing utility 'rsync'"
        echo "         runtime files will not be the most updated"
        sleep 2
    fi
    echo "---"
}

SVN_WARN_ERRORS() { # $1-status code
    if test "$1" != 0; then
        echo "svn returned error(s). Press Enter to continue, Ctrl-C to stop"
        read DUMMY
    fi
}

CHECK_SVN_LOCAL_MODS() {
    echo "    * checking for locally modified files ..."
    cd $DIR/vim7 || exit 1
    MODS=`svn st | grep '^M'|grep -v ' runtime/'|grep -v ' src/auto/'`
    if test "$MODS" = ""; then
        echo "No locally modified files"  
    else
        while true ; do
            echo "**** Found locally modified files (dir=`pwd`) ***** "
            echo "$MODS"
            echo "**** Found locally modified files (dir=`pwd`) ***** "
            echo "Select" 
            echo "(1) Discard local changes"
            echo "(2) Keep local changes"
            echo "[1] ?"
            read ANS
            case $ANS in 
            1|"")
                echo "    * removing locally modified files"
                delfiles=`echo "$MODS" | sed 's/^.//'`
                ( set -x ; rm $delfiles )
                break
            ;;
            2)
                break
            esac
        done
    fi
}


DO_SVN() { # $1 - svn option. We might want to pass -N to check out 
           # $BLD/configure, for help text only.
    ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC

    cd "${DIR?}" || exit 1

    type svn >/dev/null 2>&1 || \
        die "Error: 'svn' utility is not installed. Please install svn and retry."

    case $DOWNLOAD_METHOD in
    "svnexport")
        # every svn export is fresh download
        rm -rf ${DIR?}/* ${DIR?}/.??*
        if ( set -x; svn export --force $SVN_URL ${DIR?}/vim7 ); then
            echo "ok, 'svn export' completed to ${DIR?}/vim7"
        else
            echo svn export reported errors, Press Enter to ignore or Ctrl-C to abort.
            read ANS
        fi
      ;;
    "svn")
        # if SVN_URL changed, we erase old checkout
        OLD_URL=`svn info $DIR/vim7 2>/dev/null | awk '$1=="URL:" { print $2}'`
        if test -d $DIR/vim7/.svn -a "$OLD_URL" != "$SVN_URL" ; then
            echo "svn url changed, forcing full checkout."
            echo "    old url: $OLD_URL"
            echo "    new url: $SVN_URL"
            sleep 2
            rm -rf $DIR/vim7    # SVN_URL changed, force full checkout
        fi

        if test -d $DIR/vim7/.svn ; then
            echo "# previously downloaded source found."
            CHECK_SVN_LOCAL_MODS

            ( set -x; cd $DIR/vim7 && svn up )

            SVN_WARN_ERRORS $?
        else
            ( set -x; cd $DIR && svn co $1 ${SVN_URL?} vim7 )

            SVN_WARN_ERRORS $?
        fi
    esac

    DOWNLOAD_RUNTIME_FILES
} 

DOWNLOAD() {
    case "$DOWNLOAD_METHOD" in
    "cvs")
        DO_CVS
    ;;
    "svn")
        DO_SVN
    ;;
    "svnexport")
        DO_SVN
    ;;
    *)
        die "Error, unknown download method ($1), must be 'svn' or 'svnexport' or 'cvs'"
    esac
}

HANDLE_ROOT_INSTALLATION_ERROR() {
    echo ""
    echo "Installation had errors! Enter your choice [1]:"

    while true; do
        echo ""
        echo "1) Repeat installation step using same 'su -c root '"
        echo "   Useful if you mistyped the root passord previous time"
        echo "2) Start shell in which you can do 'make install' manually"
        echo "3) Print name of directory in which 'make install' must be done"
        echo "q) Quit"

        trap "echo 'Leaving directory '`/bin/pwd`; exit 1" 0 1 2 15

        read ANS

        case $ANS in

        [qQ]*) exit 1;;

        3) for x in 1 2 3 4; do /bin/pwd; done
           sleep 2
           continue;;

        2) echo "Current dir is `/bin/pwd`"
           echo "Become root and do 'make install' in this directory"
           echo "Starting subshell ..."
           $SHELL
           exit
        ;;

        1|"") break;;

        *) continue;;

        esac
    done
}


MAKE_AND_INSTALL() { 
    cd $DIR/vim7 || exit 100

    echo "Extracted in dir $DIR"
    # set -x

    if test "$NOBUILD" != 1; then
        make distclean
        ./configure $CONFIG_OPT || \
            die "ERROR running {./configure $CONFIG_OPT} in directory $DIR"
        echo "Completed configure in dir. $DIR ..."


        make || die "ERROR in make in directory $DIR"
    fi


    if test "$SKIP_INSTALL" = 1; then
        echo "    * install skipped"
        exit
    fi


    # time for install
    SU_COMMAND="su root -c"
    while true ; do
        if test "$IS_CYGWIN" = 1 ; then
            # cygwin does not need su
            make install || die "ERROR in install in directory $DIR"
            echo "Build and install successful"
        elif test "$ASK_ROOT" = 1; then
            echo ""
            echo "Enter root password below for installation of vim7 under /usr/local/bin"
            $SU_COMMAND "make install"
            if test $? != 0; then
                HANDLE_ROOT_INSTALLATION_ERROR
                # don't break. If HANDLE_ROOT_INSTALLATION_ERROR wanted to break, it's exit.
            else
                echo 'Leaving directory '`/bin/pwd`
                break
            fi
        else
        # non-root install
            make install || die "ERROR in install in directory $DIR"
            echo "Build and install successful"
            echo ""
            break
        fi
    done

    WARN_HOME_DIR_NOT_IN_PATH
}


WARN_HOME_DIR_NOT_IN_PATH() {
    if test "$INTO_HOME" = 1; then
        IS_DIR_IN_PATH $HOME/bin
        if test $? != 0; then        
            echo "***********************************"
            echo "***********************************"
            echo '**** Warning: directory $HOME/bin is not in you PATH!'
            echo '**** You need to add directory $HOME/bin to your PATH to run new vim'
        fi
    fi
}


IS_DIR_IN_PATH() {
    # why not to use case :"$PATH": trick ?
     _rc=1
     IFS0=$IFS; IFS=":$IFS"
     for dir in $PATH ; do
        if test "$1" = "$dir"; then
            _rc=0 # found
            break
        fi
     done
     IFS=$IFS0
     return $_rc
}


INITIAL_DIALOG() { # ->$INTO_HOME, $ASK_ROOT
    case "$CONFIG_OPT" in 
    *--prefix=*) # if --prefix= is given on the command line,
                 # then skip dialogs
    ;; 
    *) 
        echo "This will download, build and install vim7 (using $DOWNLOAD_METHOD)."
        if test $uid = 0 ; then
            CONFIG_OPT="$CONFIG_OPT --prefix=/usr/local"

            echo ""
            echo "You are superuser."
            echo "Target install directory will be: /usr/local/bin"
            echo "Configure options will be: "
            echo "         ./configure $CONFIG_OPT"
            echo "Press Enter to continue, Ctrl-C to cancel"
            echo "->"
            read ENTER
        else
            echo "Select one of the following:"
            if test "$IS_CYGWIN" != 1; then
                echo "1) You know root password and you want to install"
                echo "   vim globally for all users on this computer"
                echo "   (into /usr/local/bin)"
            else
                # CYGWIN
                echo "1) You want to install vim globally for all users"
                echo "   on this computer (into /usr/local/bin)"
            fi
            echo "2) You do not know root password or you want to"
            echo "   install vim under your "'$'"HOME/bin directory"
            read ANS
            # 3rd hidden answer (3) installs under $HOME/vim/bin

            case $ANS in 
            2) CONFIG_OPT="$CONFIG_OPT --prefix=$HOME"
               INTO_HOME=1
            ;;
            1) CONFIG_OPT="$CONFIG_OPT --prefix=/usr/local"
               ASK_ROOT=1
               if test "$IS_CYGWIN" = 1; then
                    ASK_ROOT=0
               fi
            ;;
            3) CONFIG_OPT="$CONFIG_OPT --prefix=$HOME/vim"
               INTO_HOME=1
            ;;
            *) echo "Try again"
               exit 20
            esac    
        fi
    esac

    if NOT type >/dev/null 2>/dev/null rsync; then
        echo "***** Attention. Utility 'rsync' is not installed"
        echo "                 The build will complete, but the versions of \"runtime files\""
        echo "                 (docs, highlight rules, support files) will not be the latest."
        echo "                 Consider installing rsync for to have latest \"runtime files\"."
        echo "Press ENTER to continue"
        read ANS
    fi
}


SCAN_ARGV() {
    ASK_ROOT=0
    IS_CYGWIN=0
    case `uname -s` in *CYGWIN*) IS_CYGWIN=1;; esac

    while test $# != 0 ; do # argv getops parse args
        case $1 in 
        --patch*|--show-patch*)
            GETOPT_PATCH_ARGV "$1"; shift;
          ;;
        --help)
            CONFIG_HELP
            exit
        ;;
        --*) 
            CONFIG_OPT="$CONFIG_OPT $1"; shift
        ;;
        -nb) 
            NOBUILD=1; 
            shift
        ;;
        -x|-show-dir)
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            echo $DIR/vim7
            DOWNLOAD_METHOD="svn";
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            echo $DIR/vim7
            DOWNLOAD_METHOD="cvs";
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            echo $DIR/vim7
            echo $LOG
            echo $SVN_URL
            echo $RUNTIMES_RSYNC_URL
            exit
        ;;
        -y|-show-svn)
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            echo "cd $DIR && svn co $SVN_URL vim7"
            exit
        ;;
        -cvs|--cvs)
            DOWNLOAD_METHOD="cvs"; shift;
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
        ;;
        -svn|--svn|-svnco)
            DOWNLOAD_METHOD="svn"; shift;
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
        ;;
        -svnex*|-svnexport)
            DOWNLOAD_METHOD="svnexport"; shift;
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
        ;;
        clean|-clean|--clean)
            CLEAN_ALL
            exit;
        ;;
        noupdate|-noupdate|--noupdate)
            SKIP_UPDATE=1; shift
        ;;
        noinstall|-noinstall|--noinstall)
            SKIP_INSTALL=1; shift
        ;;
        -home|-user)
            CONFIG_OPT="$CONFIG_OPT --prefix=$HOME"
            echo "Will install to --prefix=$HOME ..."; echo "";
            shift
        ;;
        -global|-glob|-glo|-g)
            CONFIG_OPT="$CONFIG_OPT --prefix=/usr/local ..."; echo "";
            echo "Will install to --prefix=/usr/local"
            shift
        ;;
        -cache)
            CACHE_BASE=$2
            shift 2
            mkdir -p "$CACHE_BASE" || die Error
        ;;
        -rt|-runtime) # only download runtime files and exit
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            DOWNLOAD_RUNTIME_FILES
            exit
        ;;
        -rt-dry|-runtime-dry) # only download runtime files and exit
            ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC
            RSYNC_OPT="-n"
            DOWNLOAD_RUNTIME_FILES
            exit
        ;;
        -nort)
            NO_RUNTIME_RSYNC=1
        ;;
        *)
            echo 1>&2 "Error: bad argument: <$1>"
            echo 1>&2 ""
            dieUsage; 
            exit 100;
        esac
    done

    case $CONFIG_OPT in *--with-features=*) ;; 
    *) CONFIG_OPT="$CONFIG_OPT --with-features=huge" ;;
    esac
}

TOP_LOGIC() {

    PATCH_POST_ARGV # this is invoked before initial question(s) of the build

    INITIAL_DIALOG # ->$INTO_HOME, $ASK_ROOT

    WARN_EXISTING_PATCHES # this is invoked after initial question(s) of the build

    DOWNLOAD_PATCHES

    if test "$SKIP_UPDATE" = 1; then
        echo "    * download/updated skipped"
    else
        DOWNLOAD          # DO_SVN or DO_CVS
    fi

    APPLY_ALL_PATCHES # if they exist

    MAKE_AND_INSTALL
}

MAIN() {
    ORIG_DIR=`pwd`
    true >$LOG

    SCAN_ARGV "$@"

    TOP_LOGIC 
}

# {{{  begin external patching stuff
#  ____   _  _____ ____ _   _ ___ _   _  ____
# |  _ \ / \|_   _/ ___| | | |_ _| \ | |/ ___|
# | |_) / _ \ | || |   | |_| || ||  \| | |  _
# |  __/ ___ \| || |___|  _  || || |\  | |_| |
# |_| /_/   \_\_| \____|_| |_|___|_| \_|\____|

# --patch=:name:file-or-url

# PATCH_ARGV
# PATCH_PAIRS
# PATCH_NAMES in format "name=url ..."
# PATCH_URLS
# PATCH_LOCALS
# PATCH_PROG
# PATCH_NONE
# PATCH_KEEP
# SHOW_PATCHES

####### PATCH_LOCAL_DIR = $SRCTOP/..
#
# ${VIMSRC?}
# ${SRCTOP?}
# ${SRCTOP?}/../patching.status
# *.UNPATCHED
#
# PAIR_TO_NAME_URL() # ->$PNAME, $URL
# WILD_EXIST()
# UNPATCH()
# DOWNLOAD_PATCHES()
# TAINT_VERSION_STRING()
# GUESS_PATCH_DIR_AND_PFLAGS() # -> $PATCH_PFLAG, ->PATCH_BASE
# TRY_DRY_PATCH() # $1-basedir $2- -pN flag $3-patchfile(keep it absolute)

####### sequence
# GETOPT_PATCH_ARGV
# WARN_EXISTING_PATCHES # called POST_GETOPT
# DOWNLOAD_PATCHES
# APPLY_ALL_PATCHES

PATCH_PROG='patch -l'


HAVE_PATCHES() {
    test "$PATCH_PAIRS" != ""
}

FIND_PREPATCH_FILES() {
    find ${SRCTOP?}/. -type f -name '*.UNPATCHED'
}


SHOW_PATCHES() {
    ASSIGN_DIR 

    files=`FIND_PREPATCH_FILES`
    # ${SRCTOP?}/../patching.status
    if test "$files" = "" -a ! -f ${SRCTOP?}/../patching.status; then
        echo "No external patches."
    elif test -f ${SRCTOP?}/../patching.status; then

        echo "*** External patches of previous build ***"
        echo ""

        echo "    *** Status file ***"
        echo "       ${SRCTOP?}/../patching.status"
        echo ""

        . ${SRCTOP?}/../patching.status
        echo "    *** Names of patches ***"
        echo "        `echo $PATCH_NAMES | sed 's/^ *//'`"

        test "$files" = "" && files="<unknown>"

        echo ""
        echo "    *** Affected source files ***"
        echo "`echo $files | tr ' ' '\012' | sed 's/^/        /'`"
        echo ""
        echo "    *** Local copies of patchfiles ***"
        echo "`echo $PATCH_LOCALS | tr ' ' '\012' | sed 's/^/        /'`"
        echo ""
        echo "    *** Arguments ***"
        echo "        $PATCH_ARGV"
        echo ""
        echo "    *** Patching logs and statuses per-patch ***"


              # status     patch                          logfile
              # ---------- ------------------------------ -------------------------
              # applied
              # failed 
              # not applied
              # 12345678901

        printf 'status     patch                          logfile\n'
        printf '---------- ------------------------------ -------------------------\n'
        for patch in $PATCH_LOCALS; do
            PATCH_LOG=$patch.patchlog
            PATCH_STATUS=$patch.patchstatus
            if NOT test -f $PATCH_STATUS ; then
                status="not applied"
            elif test "`cat $PATCH_STATUS`" = 0; then
                status="applied,ok"
            else
                status="failed"
            fi
            printf '%-11s %-25s %s\n' "$status" "`basename $patch`" "$PATCH_LOG"
        done


        echo ""
        echo "    *** Version string add-on ***"
        modby=`grep <$VIMSRC/version.h 'define.*MODIFIED_BY' | sed 's/^#define MODIFIED_BY //'`
        echo "        $modby"
    elif test "$files" != ""; then
        # some unclean state. build/patching was interrupted.
        # missing patching.status but found *.UNPATCHED files
        echo "Previous build had <unknown> external patches"
        echo "Affected source files: $files"
        echo "Previous build was probably interrupted."
    fi
    exit
}


PATCH_POST_ARGV() { # invoked before initial questio(s) of the build
    LOG "PATCH_POST_ARGV: SHOW_PATCHES=$SHOW_PATCHES"
    if test "$SHOW_PATCHES" = 1; then
        SHOW_PATCHES
        exit
    fi
}


WARN_EXISTING_PATCHES() { # invoked AFTER initial questio(s) of the build

    ASSIGN_DIR  # -> $DIR, $SRCTOP, $VIMSRC

    LOG "WARN_EXISTING_PATCHES: SHOW_PATCHES=$SHOW_PATCHES"
    if test "$SHOW_PATCHES" = 1; then
        SHOW_PATCHES
        exit
    fi


    { # begin process $PATCH_KEEP, $PATCH_NONE
        if test "$PATCH_KEEP" = 1 -a "$PATCH_NONE" = 1; then
            die "Error. You cannot specify both --patch=none and --patch=keep"
        fi
        if test "$PATCH_NONE" = 1 -a "$PATCH_ARGV" != "" ; then
            die "Error. You cannot specify patches on command line and --patch=none"
        fi
        if test "$PATCH_NONE" = 1 ; then
            UNPATCH
            return
        fi
        if test "$PATCH_KEEP" = 1 ; then
            echo "    * Restoring patch status from last build ..."
            if test ${SRCTOP?}/../patching.status ; then
                . ${SRCTOP?}/../patching.status || exit 1
                echo "Restores (patches=$PATCH_NAMES)"
            else
                echo "No patches found"
            fi
        fi
    } # end process $PATCH_KEEP, $PATCH_NONE


    # if new --patch args are given ,we do not want about old patches in the source
    # we just erase old patches silently
    # if no --patch args are given and we detect old patches, we ask


    if test "$PATCH_ARGV" != ""; then
        echo "Erasing previous external patches if any ..."
        UNPATCH
    else # new --patch args were given

        echo "Checking for previous external patches ..."

        if test -f ${SRCTOP?}/../patching.status ; then

            # if no --patch args were given and we see previous patches, we ask user

            if test -f ${SRCTOP?}/../patching.status; then
                old_patches=`. ${SRCTOP?}/../patching.status 2>&1; echo $PATCH_NAMES`
            fi
            test "$old_patches" = "" && old_patches=unkwnown
            echo "Last build had external patches ($old_patches)"
            echo "Select "
            echo "(1) delete all external patches"
            echo "(2) keep previous patches (by re-applying them to the updated vim source)"
            echo "[1] ?"

            read ANS
            case $ANS in
            1|"") UNPATCH
              ;;
            2)
                . ${SRCTOP?}/../patching.status || exit 1
                UNPATCH
            esac

        else
            echo None
            UNPATCH
        fi

        UNPATCH
    fi
}


TRY_DRY_PATCH() { # $1-basedir $2- -pN flag $3-patchfile(keep it absolute)
                  # changes current dir
    _dir=$1
    _pflag=$2
    _pfile=$3
    cd $_dir || die "Error in chdir to $1"
    test -f $_pfile || "Error, no such patchfile $1"


    type patch >/dev/null 2>&1 \
        || die "Error: utility 'patch' is not installed. Install patch and try again".


    # we have it documented that patch utility must be GNU patch
    $PATCH_PROG --dry-run </dev/null || {
        die \
"Error: this 'patch' utility does not understand the '--dry-run' option.
        Please use the --patch-prog='prog [args]' to specify the alternate patch program.
        Please install the GNU patch that understands '--dry-run' and try again.
        Or report your OS and patch version to: Yakov Lerner <iler.ml@gmail.com>"
    }

    $PATCH_PROG -s -t --dry-run $_pflag <$_pfile 
}


GUESS_PATCH_DIR_AND_PFLAGS() { # -> $PATCH_PFLAG, ->PATCH_BASE
   : ${VIMSRC?} ${SRCTOP?} # 

# we detect four compbinaitons of -pN and base dir:
# 1) -p1 in src/..
# 2) -p0 in src/..
# 3) -p0 in src/.
# 4) none -pN in src/.
    ASSIGN_DIR # -> $DIR, $SRCTOP, $VIMSRC

    PATCH_PFLAG="-p1"
    PATCH_BASE=${SRCTOP?}
    TRY_DRY_PATCH "$PATCH_BASE" "$PATCH_PFLAG" "$1" && return 0;

    PATCH_PFLAG="-p0"
    PATCH_BASE=${SRCTOP?}
    TRY_DRY_PATCH "$PATCH_BASE" "$PATCH_PFLAG" "$1" && return 0;

    PATCH_PFLAG="-p0"
    PATCH_BASE=${VIMSRC?}
    TRY_DRY_PATCH "$PATCH_BASE" "$PATCH_PFLAG" "$1" && return 0;

    PATCH_PFLAG=""
    PATCH_BASE=${VIMSRC?}
    TRY_DRY_PATCH "$PATCH_BASE" "$PATCH_PFLAG" "$1" && return 0;

    die "Error trying to apply patch $1
Tried following options: 
        cd $SRCTOP; $PATCH_PROG -p1 <$1
        cd $SRCTOP; $PATCH_PROG -p0 <$1
        cd $VIMSRC; $PATCH_PROG -p0 <$1
        cd $VIMSRC; $PATCH_PROG <$1
";  
}


PAIR_TO_NAME_URL() { # ->$PNAME, $URL
    # format of the pair is name=url
    PNAME=`echo "$1" | sed 's/=.*//'`
    URL=`echo "$1" | sed 's/^[^=]*=//'`
}


WILD_EXIST() {
    set $*
    test -f "$1"
}


UNPATCH() { # delete patches, erase patches
    echo "    * removing previous external patches ..."
    find ${SRCTOP?}/. -type f -name '*.UNPATCHED' | while read unpat ; do
        src=`dirname $unpat`/`basename $unpat .UNPATCHED`
        ( set -x; rm -f $unpat )
        ( set -x; rm -f $src )
    done
    

    mkdir -p ${SRCTOP?}/old_patches
    if test -f ${SRCTOP?}/../patching.status; then
        mv ${SRCTOP?}/../patching.status ${SRCTOP?}/old_patches
    fi
    if WILD_EXIST ${SRCTOP?}/../*.patch.*; then
        mv ${SRCTOP?}/../*.patch.* ${SRCTOP?}/old_patches
    fi

    echo Done.
}


DOWNLOAD_PATCHES() {
# we store patching.status and local patchfiles in $SRCTOP/..

    : ${SRCTOP?}

    mkdir -p ${SRCTOP?}/../old_patches

    if  WILD_EXIST ${SRCTOP?}/*.patch.* ; then
        mv ${SRCTOP?}/*.patch.* ${SRCTOP?}/../old_patches 
    fi

    LOG "DOWNLOAD_PATCHES: PATCH_PAIRS=<$PATCH_PAIRS>"

    for pair in $PATCH_PAIRS; do

        PAIR_TO_NAME_URL "$pair" # ->$PNAME, $URL

        # $PNAME, $URL

        k=1
        fname=${SRCTOP?}/../$PNAME.patch.`printf "%03d" "$k"`
        while test -f "$fname" ; do
            k=`expr $k + 1`
            fname=${SRCTOP?}/../$PNAME.patch.`printf "%03d" "$k"`
        done

        # $fname

        : ${ORIG_DIR?}
        case $URL in

        file:*)
            # URL is local filename
            from=`echo "$URL" | sed 's@^file:@@'`
            case $URL in /*) abs=$from;; *) abs=${ORIG_DIR?}/$from;; esac
            test -f "$abs" || die "Error: No such file: $abs"
            cp "$abs" "$fname" || die "Error copying patch from '$abs' to '$fname' "
          ;;

        *://*)
            rm -f $fname $fname+
            dir=`dirname $fname`
            test -w `dirname $fname` || die "Error downloading patch, dir. $dir is not writable"
            wget -O $fname+ "$URL" || die "Error downloading patch from $URL"
                        # will be change wget to $WGET or something ...
            mv $fname+ $fname || die "Error renaming patch file"
          ;;

        *)
            # assume it is local filename
            case $URL in /*) abs=$URL;; *) abs=${ORIG_DIR?}/$URL;; esac
            test -f "$abs" || die "Error: No such file: $abs"
            cp "$abs" "$fname" || die "Error copying patch from '$abs' to '$fname' "
        esac

        echo "    ... downloaded patch $fname"
        PATCH_LOCALS="$PATCH_LOCALS $fname"
    done
}


TAINT_VERSION_STRING() {
# MODIFIED_BY
# Possibilities:
# patch version.h
# patch features.h
# patch version.c
    echo "    * Creating version MODIFIED_BY string for external patches ..."


    cp ${VIMSRC?}/version.h ${VIMSRC?}/version.h.UNPATCHED

    NPATCHES=`set -- $PATCH_NAMES ; echo $#`
    case $NPATCHES in 1) patch__="patch";; *) patch__="patches";; esac


# Modified by external patches: 'autopaste', 'conceal'.
# Modified by external patch 'conceal'.


    cat >>${VIMSRC?}/version.h <<EOF
/* Following lines was added by vim7-install.sh build script. */
#undef MODIFIED_BY
EOF
    if test "$NPATCHES" = 1; then
        trimmed=`echo $PATCH_NAMES`
        cat >>${VIMSRC?}/version.h <<EOF
#define MODIFIED_BY "external patch '$trimmed'. *** Use at your own risk ***"
EOF
    else
        # Modified by external patches: 'autopaste', 'conceal'.
        QUOTED_PATCHES=`echo "$PATCH_NAMES" | 
                        perl -ane 'for(@F){ printf "%c%s%c",39,$_,39;$k++; printf ", " if($K<@F); }'`

        cat >>${VIMSRC?}/version.h <<EOF
#define MODIFIED_BY "external patches: $QUOTED_PATCHES. *** Use at your own risk ***"
EOF
    fi
}


PRE_SAVE_PATCHED_FILES() {
    for patch in $PATCH_LOCALS; do
        # we need to pass abs. patch names to GUESS_PATCH_DIR_AND_PFLAGS
        # indeed, $PATCH_LOCALS contains full pathnames

        GUESS_PATCH_DIR_AND_PFLAGS $patch || exit 1 ; # -> $PATCH_PFLAG, ->PATCH_BASE
        LOG "PRE_SAVE_PATCHED_FILES: PATCH_PFLAG=$PATCH_PFLAG"
        LOG "PRE_SAVE_PATCHED_FILES: PATCH_BASE=$PATCH_BASE"

        cd $PATCH_BASE || exit
        # current dir = $PATCH_BASE

        if test "$PATCH_PFLAG" != ""; then
            files=`FILENAMES_FROM_PATCH $PATCH_PFLAG <$patch` || exit 1
        else
            # empty -pN option to patch means take basenames of all files, strip all dirnames
            files1=`FILENAMES_FROM_PATCH -p0 <$patch` || exit 1
            files=`echo "%files" | while read x; do basename $x; done`
        fi
        LOG "PRE_SAVE_PATCHED_FILES: patch = $patch"
        LOG "PRE_SAVE_PATCHED_FILES: files=$files"

        found=0

        for f in $files; do
            if test -f $f; then
                cp $f $f.UNPATCHED
                found=1
            fi
        done
        # we die if none of files were found
        if test "$found" = 0; then
            die "Error. No files from patch $patch were found (files=$files; in directory $PATCH_BASE)"
        fi
    done
}


APPLY_ALL_PATCHES() {

    LOG "APPLY_ALL_PATCHES: PATCH_LOCALS=<$PATCH_LOCALS>"

    test "$PATCH_LOCALS" = "" && return

    SAVE_PATCH_STATE

    PRE_SAVE_PATCHED_FILES

    TAINT_VERSION_STRING

    rm -f $PATCH_BASE/*.patchlog $PATCH_BASE/*.patchstatus
    # shall not these cleanup be in 

    for patch in $PATCH_LOCALS; do
        # we need to pass abs. patch names to GUESS_PATCH_DIR_AND_PFLAGS
        # indeed, $PATCH_LOCALS contains full pathnames

        GUESS_PATCH_DIR_AND_PFLAGS $patch || exit 1 ; # -> $PATCH_PFLAG, ->PATCH_BASE

        cd $PATCH_BASE || exit
        # current dir = $PATCH_BASE

        PATCH_LOG=$patch.patchlog
        PATCH_STATUS=$patch.patchstatus
        ( set -x; patch $PATCH_PFLAG <$patch >$PATCH_LOG 2>&1 )
        status=$?
        echo $status >$PATCH_STATUS
        if test $status != 0; then
            echo "Error applying patch 'patch $PATCH_PFLAG <$patch' in directory `pwd`"
            echo "Select (1) quit (2) start subshell so you can edit files (3) ignore error (bad idea) [1]"
            read ANS
            case $ANS in
            1|"") exit 1;;
            2) 
                pwd
                $SHELL
                echo "We are after patch error from patch $patch"
                echo "Select (1) continue with the build (2) quit ? [1]"

                read ANS

                case $ANS in
                1|"") ;; 
                2) exit 1;;
                esac
              ;;
            3)
                ;;
            *)
                exit 1
            esac
        else
            echo patch applied.
        fi
    done
}


FILENAMES_FROM_PATCH() {
    STRIP() {
        x=$1
        n=0
        while test $n -lt $NSTRIP; do
            x=`echo "$x" | sed 's:^[^/]*/::'`
            n=`expr $n + 1`
        done
        echo "$x"
    }

    PATCH2FILENAMES() {
        NSTRIP=0
        case $# in 1) ;; *) dieUsage ;; esac
        case $1 in -p[0-9]*) NSTRIP=`echo "$1" | sed 's/^-p//'`;;
        *) dieUsage ;;
        esac

        # for -u diff format, we want filename from +++ lines.
        # for -c diff format, we want filename from next line after '***' lines

        perl -ane 'if(/^\+\+\+ /) { print $F[1], "\n"; }
        if(/^\*\*\* / && !/^\*\*\* \d+,\d+ \*\*\*/) {
                $_=<>; @F=split(" ",$_); print $F[1],"\n";
        }
        ' | while read a; do
            STRIP "$a"
        done
    }
    PATCH2FILENAMES "$@"
}


SAVE_PATCH_STATE() {
    cat <<EOF >${SRCTOP?}/../patching.status
PATCH_ARGV='$PATCH_ARGV'
PATCH_PAIRS='$PATCH_PAIRS'
PATCH_NAMES='$PATCH_NAMES'
PATCH_URLS='$PATCH_URLS'
PATCH_LOCALS='$PATCH_LOCALS'
EOF
}


GETOPT_PATCH_ARGV() {
  # process arg in the form 
  # --patch=:na:'am.
    case $1 in 
    --patch=:*:*)
        tail=`echo "$1" | sed 's/^--patch=://'`
        name=`echo "$tail" | sed 's/:.*//'`
        url=`echo "$tail" | sed 's/^[^:]*://'`
        test "$name" = "" && die "Error. Patch name empty in $1"
        test "$url" = "" && die "Error. URL is empty in $1"

        # what of name has chars that prevent it from using in filename (basically, slash)
        name=`echo "$name" | sed 's;[/ ];-;g'`
        # url cannot contain spaces
        case $url in *" "*) die "Error. URL cannot have spaces ($1)".;; esac

        PATCH_ARGV="$PATCH_ARGV $1"
        PATCH_PAIRS="$PATCH_PAIRS $name=$url"
        PATCH_NAMES="$PATCH_NAMES $name"
        PATCH_URLS="$PATCH_URLS $url"
        # PATCH_LOCALS is populated later
      ;;
    --patch-prog=*)
        PATCH_PROG=`echo "$1" | sed 's/^--patch-prog=//'`
      ;;
    --patch=none|--patch=no)
        PATCH_NONE=1
      ;;
    --patch=same|--patch=keep)
        PATCH_KEEP=1
      ;;
    --patch-show|--show-patch|--show-patches)
        SHOW_PATCHES=1
        # we must wait till post-argv. we cannot invoke all printing here
        # because we must wait untill all other (-svn,-cvs) args
        # were scanned in.
      ;;
    *)
        die "Error. Patch argument must have form --patch=:name:url-or-filename"
    esac
}


CHECK_PREVOUS_PATCHES() {
    prepatch=`find ${SRCTOP}/. -type f -name '*.UNPATCHED'`
    test "$prepatch" != ""
}


#  ____   _  _____ ____ _   _ ___ _   _  ____
# |  _ \ / \|_   _/ ___| | | |_ _| \ | |/ ___|
# | |_) / _ \ | || |   | |_| || ||  \| | |  _
# |  __/ ___ \| || |___|  _  || || |\  | |_| |
# |_| /_/   \_\_| \____|_| |_|___|_| \_|\____|
# }}}


    # I have some doubts about putting copy of configure-help into here.
    # The plus is that you can see --help immediately even before checkout.
    # It would be nice if I could put it at then end of script
    # Oh well, actually I can
STORED_CONFIGURE_HELP_COPY()
{
    # if $BLD/configure file is present, we obtain --help from
    # if $BLD/configure file is not present, we use stored copy
cat <<'EOF'
------------------------------------------------------------
configure help
------------------------------------------------------------
`configure' configures this package to adapt to many kinds of systems.

Usage: auto/configure [OPTION]... [VAR=VALUE]...

To assign environment variables (e.g., CC, CFLAGS...), specify them as
VAR=VALUE.  See below for descriptions of some of the useful variables.

Defaults for the options are specified in brackets.

Configuration:
  -h, --help              display this help and exit
      --help=short        display options specific to this package
      --help=recursive    display the short help of all the included packages
  -V, --version           display version information and exit
  -q, --quiet, --silent   do not print `checking...' messages
      --cache-file=FILE   cache test results in FILE [disabled]
  -C, --config-cache      alias for `--cache-file=config.cache'
  -n, --no-create         do not create output files
      --srcdir=DIR        find the sources in DIR [configure dir or `..']

Installation directories:
  --prefix=PREFIX         install architecture-independent files in PREFIX
			  [/usr/local]
  --exec-prefix=EPREFIX   install architecture-dependent files in EPREFIX
			  [PREFIX]

By default, `make install' will install all the files in
`/usr/local/bin', `/usr/local/lib' etc.  You can specify
an installation prefix other than `/usr/local' using `--prefix',
for instance `--prefix=$HOME'.

For better control, use the options below.

Fine tuning of the installation directories:
  --bindir=DIR           user executables [EPREFIX/bin]
  --sbindir=DIR          system admin executables [EPREFIX/sbin]
  --libexecdir=DIR       program executables [EPREFIX/libexec]
  --datadir=DIR          read-only architecture-independent data [PREFIX/share]
  --sysconfdir=DIR       read-only single-machine data [PREFIX/etc]
  --sharedstatedir=DIR   modifiable architecture-independent data [PREFIX/com]
  --localstatedir=DIR    modifiable single-machine data [PREFIX/var]
  --libdir=DIR           object code libraries [EPREFIX/lib]
  --includedir=DIR       C header files [PREFIX/include]
  --oldincludedir=DIR    C header files for non-gcc [/usr/include]
  --infodir=DIR          info documentation [PREFIX/info]
  --mandir=DIR           man documentation [PREFIX/man]

X features:
  --x-includes=DIR    X include files are in DIR
  --x-libraries=DIR   X library files are in DIR

Optional Features:
  --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
  --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
  --disable-darwin        Disable Darwin (Mac OS X) support.
  --disable-xsmp          Disable XSMP session management
  --disable-xsmp-interact Disable XSMP interaction
  --enable-mzschemeinterp   Include MzScheme interpreter.
  --enable-perlinterp     Include Perl interpreter.
  --enable-pythoninterp   Include Python interpreter.
  --enable-tclinterp      Include Tcl interpreter.
  --enable-rubyinterp     Include Ruby interpreter.
  --enable-cscope         Include cscope interface.
  --enable-workshop       Include Sun Visual Workshop support.
  --disable-netbeans      Disable NetBeans integration support.
  --enable-sniff          Include Sniff interface.
  --enable-multibyte      Include multibyte editing support.
  --enable-hangulinput    Include Hangul input support.
  --enable-xim            Include XIM input support.
  --enable-fontset        Include X fontset output support.
  --enable-gui=OPTS     X11 GUI default=auto OPTS=auto/no/gtk/gtk2/gnome/gnome2/motif/athena/neXtaw/photon/carbon
  --enable-gtk-check      If auto-select GUI, check for GTK default=yes
  --enable-gtk2-check     If GTK GUI, check for GTK+ 2 default=yes
  --enable-gnome-check    If GTK GUI, check for GNOME default=no
  --enable-motif-check    If auto-select GUI, check for Motif default=yes
  --enable-athena-check   If auto-select GUI, check for Athena default=yes
  --enable-nextaw-check   If auto-select GUI, check for neXtaw default=yes
  --enable-carbon-check   If auto-select GUI, check for Carbon default=yes
  --disable-gtktest       Do not try to compile and run a test GTK program
  --disable-acl           Don't check for ACL support.
  --disable-gpm           Don't use gpm (Linux mouse daemon).
  --disable-nls           Don't support NLS (gettext()).

Optional Packages:
  --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
  --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
  --with-mac-arch=ARCH    current, intel, ppc or both
  --with-vim-name=NAME    what to call the Vim executable
  --with-ex-name=NAME     what to call the Ex executable
  --with-view-name=NAME   what to call the View executable
  --with-global-runtime=DIR    global runtime directory in 'runtimepath'
  --with-modified-by=NAME       name of who modified a release version
  --with-features=TYPE    tiny, small, normal, big or huge (default: normal)
  --with-compiledby=NAME  name to show in :version message
  --with-plthome=PLTHOME   Use PLTHOME.
  --with-python-config-dir=PATH  Python's config directory
  --with-tclsh=PATH       which tclsh to use (default: tclsh8.0)
  --with-x                use the X Window System
  --with-gtk-prefix=PFX   Prefix where GTK is installed (optional)
  --with-gtk-exec-prefix=PFX Exec prefix where GTK is installed (optional)
  --with-gnome-includes=DIR Specify location of GNOME headers
  --with-gnome-libs=DIR   Specify location of GNOME libs
  --with-gnome            Specify prefix for GNOME files
  --with-motif-lib=STRING   Library for Motif
  --with-tlib=library     terminal library to be used

Some influential environment variables:
  CC          C compiler command
  CFLAGS      C compiler flags
  LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
              nonstandard directory <lib dir>
  CPPFLAGS    C/C++ preprocessor flags, e.g. -I<include dir> if you have
              headers in a nonstandard directory <include dir>
  CPP         C preprocessor

Use these variables to override the choices made by `configure' or to help
it to find libraries and programs with nonstandard names/locations.
EOF
}



MAIN "$@"

# ------ Todo --------
# force "$ASK_ROOT" if prefix is not writable 
# XXX we need to try svn twice (on OSX, fails 1st time)
# XXX  (c) "Customize Build Options" in top menu
# XXX  -> (I) include all interpreters  (i) include perl/python/ruby/scheme
# XXX  -> (t) change target dir prefix
# XXX  -> (g) select gui option
# XXX  -> detect gui option of existing vim 
# XXX  -> (s) select build size
# XXX in "local mods" dialog, add [3] show modified files

#------------------------------------------------------------------
#Recent changes
#------------------------------------------------------------------
# 061019 lerner added cvs option
# 061019 lerner added '-clean' option
# 061103 lerner added check for locally changed files, and prompt.
# 070510 lerner SVN_URL changed
# 070511 lerner added -cache option
# 080220 lerner  added $VARTMP env.var
# 080220 lerner  added rsync for runtime files, options -rt, -rt-dry, -nort
# 080318 lerner fixed $uid on Solaris
