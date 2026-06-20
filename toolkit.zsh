# toolkit.zsh — zsh port of ~/bin/toolkit (bash)
#
# Auto-loaded by oh-my-zsh because it lives in custom/ and ends in .zsh.
# Ported idiomatically to zsh: real arrays, `whence -p` instead of `which`,
# `${commands[time]}` instead of `which time` (zsh's `time` is a keyword),
# native dirstack handling, and zsh parameter modifiers (:t :h :e :A).
#
# Bash `complete` completion definitions were intentionally dropped.

# GNU /usr/bin/time — `which time` can't find it in zsh (`time` is a reserved
# word), so resolve the external command via the $commands hash once.
typeset -g _TOOLKIT_TIME=${commands[time]}

# Config files consumed by rgubin-based helpers.
typeset -g RGUBIN_GR_CFG=$HOME/.gr.${USER}.env
typeset -g RGUBIN_CFG=$HOME/.gv.${USER}.env

# ---------------------------------------------------------------------------
# directory-stack helpers
# ---------------------------------------------------------------------------

# Split args into option flags (-x) and the rest, then sort the rest with the
# collected flags. Prints the sorted operands space-separated.
sortpara() {
	emulate -L zsh
	local tp
	local -a opt para
	for tp in "$@"; do
		if [[ $tp == -[[:alpha:]]* ]]; then
			opt+=$tp
		else
			para+=$tp
		fi
	done
	print -l -- $para | sort $opt | tr '\n' ' '
}

# Print the directory stack as "(index) /full/path", current dir first.
showdirs() {
	emulate -L zsh
	local -a stack
	stack=( ${(f)"$(dirs -lp)"} )
	local i
	for (( i = 1; i <= ${#stack}; i++ )); do
		print -r -- "($(( i - 1 ))) ${stack[i]}"
	done
}

# Absolute, symlink-resolved path of $1.
getfullname() {
	emulate -L zsh
	print -r -- ${1:A}
}

# Echo all args except the first.
skiptop() {
	emulate -L zsh
	shift
	print -r -- "$*"
}

# Indices in the dir stack whose path is exactly $1 (resolved).
searchdirs() {
	emulate -L zsh
	local obj=${1:A}
	local -a stack
	stack=( ${(f)"$(dirs -lp)"} )
	local i
	for (( i = 1; i <= ${#stack}; i++ )); do
		[[ ${stack[i]} == "$obj" ]] && print -r -- $(( i - 1 ))
	done
}

# Indices in the dir stack whose path ends with $1.
searchdirs_likely() {
	emulate -L zsh
	local obj=$1
	local -a stack
	stack=( ${(f)"$(dirs -lp)"} )
	local i
	for (( i = 1; i <= ${#stack}; i++ )); do
		[[ ${stack[i]} == *"$obj" ]] && print -r -- $(( i - 1 ))
	done
}

# ---------------------------------------------------------------------------
# go wrapper (dispatches real `go` subcommands, else falls through to gu)
# ---------------------------------------------------------------------------

go() {
	emulate -L zsh
	local orig_go
	orig_go=$(whence -p go 2>/dev/null)
	if [[ -n $orig_go ]]; then
		case "$1" in
			bug|build|clean|doc|env|fix|fmt|generate|get|install|list|mod|run|test|tool|version|help|vet)
				$orig_go "$@" ;;
			*)
				gu "$@" ;;
		esac
	else
		gu "$@"
	fi
}

go-help() {
	emulate -L zsh
	go help "$1"
}

# ---------------------------------------------------------------------------
# gu / gr family
# ---------------------------------------------------------------------------

# Legacy pushd/popd-based jump (superseded by gu); kept for compatibility.
gu0() {
	emulate -L zsh
	local index_likely ct tr
	local -a idx
	print -r -- "-----$1"

	if [[ -n $1 ]]; then
		if [[ -d $1 || -L $1 ]]; then
			idx=( ${(f)"$(searchdirs $1)"} )
			idx=( ${idx:#} )
			if (( ${#idx} )); then
				ct=0
				for tr in ${idx[2,-1]}; do
					(( tr -= ct ))
					popd +$tr >/dev/null
					(( ct++ ))
				done
				pushd +${idx[1]} >/dev/null
			else
				pushd $1 >/dev/null
			fi
		else
			index_likely=$(searchdirs_likely $1)
			index_likely=${index_likely%%[$'\n']*}
			if [[ -z $index_likely ]]; then
				pushd +$1 >/dev/null 2>&1
			else
				pushd +$index_likely >/dev/null
			fi
		fi
	fi

	showdirs
	print -r -- "-----"
	ls
}


grdel() {
	emulate -L zsh
	local sorted tgt
	sorted=$(sortpara -r -n "$@")
	for tgt in ${=sorted}; do
		rgubin -r $tgt
	done
}

do_gr() {
	emulate -L zsh
	local topath=""
	if [[ -n "$*" ]]; then
		topath=$(rgubin -n "$@")
	fi
	print -r -- "-----$topath"
	[[ -n $topath ]] && cd $topath
	rgubin -f $RGUBIN_GR_CFG -p
	print -r -- "-----"
	ls
}

_sel() {
	emulate -L zsh
	rgubin -f $RGUBIN_GR_CFG -p -t d
	eza -Dg
}

gr() {
	emulate -L zsh
	local topath="" t
	if [[ -n "$*" ]]; then
		topath=$(rgubin -f $RGUBIN_GR_CFG -t d -n "$@")
	fi

	if [[ -n $topath ]]; then
		cd $topath
		return
	fi

	t=$( _sel | fzf --layout=reverse --info=hidden -i --header="Selection:" )
	topath=${${(s: :)t}[2]}
	do_gr $topath
}

# Pop entries off the dir stack: a specific +N, or collapse to the current dir.
bk() {
	emulate -L zsh
	print -r -- "-----$1"
	if [[ -n $1 ]]; then
		popd +$1 >/dev/null
	else
		local i
		for (( i = ${#dirstack}; i > 0; i-- )); do
			popd +1 >/dev/null
		done
	fi
	showdirs
}

# Open a file located via rgubin (config $RGUBIN_CFG), with fzf fallback.
gw() {
	emulate -L zsh
	local tf="" tfr
	if [[ -n "$*" ]]; then
		tf=$(rgubin -f $RGUBIN_CFG -n "$@" -t f)
		if [[ -n $tf ]]; then
			nvim $tf
			return
		fi
		tfr=$(rgubin -f $RGUBIN_CFG -p -e "$@" -t f | fzf --layout=reverse --info=hidden -i --header="Selection:")
	else
		tfr=$(rgubin -f $RGUBIN_CFG -p -t f -e "<Quit>" | fzf --layout=reverse --info=hidden -i --header="Selection:")
	fi

	tf=${${(s: :)tfr}[2]}
	[[ -z $tf ]] && return
	[[ $tf == "<Quit>" ]] && return
	nvim $tf
}

# ---------------------------------------------------------------------------
# misc utilities
# ---------------------------------------------------------------------------

find_file_type() {
	emulate -L zsh
	local tdir=$1
	shift
	find $tdir "$@" -exec file -i '{}' \;
}

nocolor() {
	emulate -L zsh
	sed -r "s:\x1B\[[0-9;]*[mK]::g" ${1:-/dev/stdin}
}

noCtrlM() {
	emulate -L zsh
	tr -d '\r' < ${1:-/dev/stdin}
}

srctree() {
	emulate -L zsh
	find $1 -type d | sort | sed -ne'1b;s/[^\/]*\//+--/g;s/+--+/|  +/g;s/+--+/|  +/g;s/+--|/|  |/g;p'
}

srctree_opt() {
	emulate -L zsh
	find $1 \( -path "*.git" -o -path "*.deps" \) -prune -o -type d | sort | sed -ne'1b;s/[^\/]*\//+--/g;s/+--+/|  +/g;s/+--+/|  +/g;s/+--|/|  |/g;p'
}

need_reboot() {
	emulate -L zsh
	[[ -f /var/run/reboot-required ]] && cat /var/run/reboot-required
}

# ---------------------------------------------------------------------------
# compression helpers
# ---------------------------------------------------------------------------

# Low-level single-file compressor. $here is read from the caller (comp) via
# zsh's dynamic scoping, matching the original bash behaviour.
compress() {
	emulate -L zsh
	local cmd=$1 level=$2 infile=$3 tohere=$4
	local mark dotar
	local best=9 fast=1
	local ext=$1 realname=${infile%%.*}
	local wtime mem origsize compsize comprate

	if [[ $5 != no ]]; then
		mark=_${5}
	else
		mark=
	fi
	if [[ $6 == yes ]]; then
		dotar=.tar
	else
		dotar=
	fi

	case $cmd in
		gzip)        ext=gz ;;
		bzip2)       ext=bz2 ;;
		xz|lzop|lz4) ;;
		zip)         ext=zip ;;
		brotli)      best=11; fast=0 ;;
	esac

	(( level >= best )) && level=$best
	(( level <= fast )) && level=$fast

	case $cmd in
		gzip|bzip2|xz|lzop|lz4)
			$_TOOLKIT_TIME -f "%E %M" -o .comp.log $cmd -$level $infile -c > ${realname}${mark}${dotar}.${ext} ;;
		zip)
			$_TOOLKIT_TIME -f "%E %M" -o .comp.log $cmd ${realname}${mark}${dotar}.${ext} ${infile} ;;
		brotli)
			$_TOOLKIT_TIME -f "%E %M" -o .comp.log $cmd --quality=$level --output=${realname}${mark}${dotar}.${ext} $infile ;;
	esac

	wtime=$(awk '{print $1}' .comp.log)
	mem=$(awk '{print $2}' .comp.log)
	origsize=$(stat -c "%s" $infile)
	compsize=$(stat -c "%s" ${realname}${mark}${dotar}.${ext})
	comprate=$(print -r -- $origsize $compsize | awk '{printf("%.3f",$2*100/$1)}')
	print -r -- "Info: $cmd  level: $level ${infile} -> ${realname}${mark}${dotar}.${ext}"
	print -r -- "      $infile $origsize B $compsize B ${comprate}% $wtime $mem KB"
	if [[ $tohere == yes ]]; then
		mv ${realname}${mark}${dotar}.${ext} ${here}
	fi
	rm .comp.log
}

comp_usage() {
	emulate -L zsh
	print -- "Usage: comp [gzip|bzip2|xz|bro|lzop|lz4] -[t|m] [ -w <filename> ] [-<Compress level>] [-h] [file1|dir1] [file2|dir2]...."
	print -- "\t -w: compress all files into one compressed tar file."
	print -- "\t -m: mv compressed file to the current directory."
	print -- "\t -t: add time infomation to compressed file name."
	print -- "\t -h: show this help message."
}

comp() {
	emulate -L zsh
	local here=$PWD
	local gcmd=gzip glevel=6
	local allinone=no allinone_file="allinone" mvtohere=no append=no istar=no
	local -a infiles
	local tp tf gfname gpath ext rl skip
	local wtime mem origsize compsize comprate

	while [[ -n $1 ]]; do
		if [[ $1 == -<-> ]]; then
			glevel=${1#-}
		elif [[ $1 == -h ]]; then
			comp_usage
			return
		elif [[ $1 == -w ]]; then
			allinone=yes
			shift
			allinone_file=$1
			[[ -z $allinone_file ]] && allinone_file=unknown
			shift
			continue
		elif [[ $1 == -m ]]; then
			mvtohere=yes
			shift
			continue
		elif [[ $1 == -t ]]; then
			append=$(date +"%Y%m%d_%H%M%S")
			shift
			continue
		else
			skip=no
			for tp in gzip bzip2 xz brotli lzop lz4 zip bz2 gz; do
				if [[ $tp == $1 ]]; then
					case $tp in
						gzip|gz)   gcmd=gzip ;;
						bzip2|bz2) gcmd=bzip2 ;;
						*)         gcmd=$tp ;;
					esac
					skip=yes
					break
				fi
			done
			if [[ $skip == yes ]]; then
				shift
				continue
			fi
			if [[ -f $1 || -d $1 ]]; then
				rl=${${1%/}:A}
				(( ${infiles[(Ie)$rl]} )) || infiles+=$rl
			else
				print -r -- "Invalid file: $1."
			fi
		fi
		shift
	done

	if (( ${#infiles} == 0 )); then
		print -r -- "No valid input file found."
		comp_usage
		return
	fi

	if [[ $allinone == yes ]]; then
		if [[ $gcmd != zip ]]; then
			rm -fr $allinone_file 2>/dev/null
			mkdir $allinone_file
			cp -raf $infiles $allinone_file
			tar cvf ${allinone_file}.tar $allinone_file 2>/dev/null
			rm -fr $allinone_file
			gfname=${allinone_file}.tar
			istar=yes
			compress $gcmd $glevel ${gfname} meanless ${append} ${istar}
			rm $gfname
		else
			gfname=${allinone_file}.zip
			$_TOOLKIT_TIME -f "%E %M" -o .comp.log zip $gfname $infiles
			wtime=$(awk '{print $1}' .comp.log)
			mem=$(awk '{print $2}' .comp.log)
			origsize="-"
			compsize=$(stat -c "%s" $gfname)
			comprate="-"
			print -r -- "Info: $gcmd  ... -> $gfname"
			print -r -- "      ... $origsize B $compsize B ${comprate}% $wtime $mem KB"
			rm .comp.log
		fi
	else
		for tf in $infiles; do
			gfname=${tf:t}
			gpath=${tf:h}
			[[ -n $gpath ]] && cd $gpath
			if [[ -d $tf ]]; then
				tar cvf ${gfname}.tar $gfname 2>/dev/null
				istar=yes
				gfname=${tf}.tar
			fi
			compress $gcmd $glevel ${gfname} $mvtohere ${append} ${istar}
			ext=${gfname:e}
			[[ $ext == tar ]] && rm $gfname
		done
		cd ${here}
	fi
}

decompress() {
	emulate -L zsh
	local infile=$1 fname=$2 cmd=$3
	local wtime mem origsize decompsize comprate

	case $cmd in
		gzip|bzip2|xz|lzop|lz4)
			$_TOOLKIT_TIME -f "%E %M" -o .decomp.log $cmd -d $infile -c > ${fname} ;;
		zip)
			$_TOOLKIT_TIME -f "%E %M" -o .decomp.log un$cmd $infile ;;
		brotli)
			$_TOOLKIT_TIME -f "%E %M" -o .decomp.log $cmd --decompress --output ${fname} $infile ;;
	esac

	wtime=$(awk '{print $1}' .decomp.log)
	mem=$(awk '{print $2}' .decomp.log)
	origsize=$(stat -c "%s" $infile)
	if [[ -f ${fname} ]]; then
		decompsize=$(stat -c "%s" ${fname})
		comprate=$(print -r -- $origsize $decompsize | awk '{OFMT="%3g"}{print $2/$1}')
	else
		decompsize="-"
		comprate="-"
	fi
	print -r -- "Info: $cmd decompress ${infile} -> ${fname}"
	print -r -- "      $infile $origsize B $decompsize B ${comprate}% $wtime $mem KB"
	rm .decomp.log
}

decomp_usage() {
	emulate -L zsh
	print -- "Usage: decomp -[h|m] [compressed file1] [compressed file2]...."
	print -- "       Recognized file extensions:"
	print -- "       .gz .bzip2 .xz .brotli .lzop .lz4"
	print -- "       .tar.gz .tar.bzip2 tar.xz .tar.bro .tar.lzop .lz4"
	print -- "\t -m: mv decompressed files to current directory."
	print -- "\t -h: show this help message."
}

decomp() {
	emulate -L zsh
	local here=$PWD
	local mvtohere=no
	local -a infiles
	local tf tp gfname gftype gpath realname ext

	while [[ -n $1 ]]; do
		if [[ $1 == -h ]]; then
			decomp_usage
			return
		fi
		if [[ $1 == -m ]]; then
			mvtohere=yes
			shift
			continue
		fi
		if [[ -f $1 ]]; then
			(( ${infiles[(Ie)$1]} )) || infiles+=$1
		else
			print -r -- "Invalid file: $1."
		fi
		shift
	done

	if (( ${#infiles} == 0 )); then
		print -r -- "No valid input file found."
		decomp_usage
		return
	fi

	for tf in $infiles; do
		gfname=${tf%.*}
		gftype=
		for tp in gz bzip2 xz brotli lzop lz4 zip bz2 gzip; do
			if [[ $tp == ${tf:e} ]]; then
				case $tp in
					gzip|gz)   gftype=gzip ;;
					bzip2|bz2) gftype=bzip2 ;;
					*)         gftype=$tp ;;
				esac
				break
			fi
		done

		if [[ -z $gftype ]]; then
			print -r -- "File type (${tf:e}) not supported."
			return
		fi

		if [[ $mvtohere == yes ]]; then
			gfname=${gfname:t}
		fi

		decompress $tf $gfname $gftype

		ext=${gfname:e}
		gpath=${gfname:h}
		realname=${gfname:t}
		if [[ $ext == tar ]]; then
			[[ -d $gpath ]] && cd $gpath
			tar xvf $realname
			rm $realname
		fi
		cd ${here}
	done
}
