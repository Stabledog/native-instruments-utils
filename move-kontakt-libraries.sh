#!/bin/bash
# move-kontakt-libraries.sh

scriptPath=$(realpath "$0")
scriptName="$(basename "${scriptPath}")"



OldRoot="/mnt/c/Users/Public/Documents"
NewRoot="/mnt/k/NativeInstrumentsLibraries"
LibList=()

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

move_lib() {
    local src="$1"
    [[ -d "${OldRoot}/${src}" ]] || { echo "Can't find ${OldRoot}/${src}" >&2; return 0; }
    set +e
    cd ${NewRoot} || die "Can't cd to ${NewRoot}"
    
    set -ue 
    mkdir -p "$src" 
    (
        set -ue
        cd "$src"
        set -o pipefail
        rsync --progress -a  "${OldRoot}/${src}/" ./  || die "Can't rsync ${src} to ${NewRoot}" 
        cd "$OldRoot"
        mv -v "$src" "_deleteme-$src"  || die "Can't mv ${src} to ${OldRoot}/deleteme"
        echo "Completed move @$(date -Iseconds)"
    ) |& sed "s/^/${src}: /" 
}


main() {
    PS4='\033[0;33m+$?( ${scriptName}:${LINENO} 2>/dev/null ):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    [[ $# -eq 0 ]] && {
        echo "Usage: $(basename "${scriptName}") [--all] <LibraryName> [<LibraryName> ...]"
        return 0
    }
    set -ue
    case $1 in
        --all) shift
            # List all real dirs that don't contain 'deleteme' in their name:
            cd ${OldRoot} || die "Can't cd to ${OldRoot}"
            mapfile -t LibList < <(find . -maxdepth 1 -type d -print0 | xargs -0 -I{} basename "{}" | grep -v deleteme | grep -E '\w+' | sort)
            printf '%s\n' "${LibList[@]}"
            ;;
        *)
            mapfile -t LibList < <(printf '%s\n' "$@")
            ;;
    esac
    for Lib in "${LibList[@]}"; do
        move_lib "${Lib}" "${NewRoot}"
    done
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
