################################################################################
# This library is modified to fit the needs of the Local Sherpa project.

# Stash/unstash support for per-directory variables
#
#   Copyright (c) 2009,2012 Dave Olszewski <cxreg@pobox.com>
#   http://github.com/cxreg/smartcd
#
#   This code is released under GPL v2 and the Artistic License, and
#   may be redistributed under the terms of either.
#
#
#   This library allows you to save the current value of a given environment
#   variable in a temporary location, so that you can modify it, and then
#   later restore its original value.
#
#   Note that you will need to be in the same directory you were in when you
#   stashed in order to successfully unstash.  This is because the temporary
#   variable is derived from your current working directory's path.
#
#   Usage:
#       varstash::stash PATH
#       export PATH=/something/else
#       [...]
#       unstash PATH
#
#   Note that this was written for use with, and works very well with,
#   smartcd.  See the documentation there for examples.
#
#   An alternate usage is `varstash::autostash' which will trigger
#   varstash::autounstash when leaving the directory, if combined with smartcd.
#   This reduces the amount of explicit configuration you need to provide:
#
#       varstash::autostash PATH
#       export PATH=/something/else
#
#   You may also do both operations in one line, resulting in the very succinct
#
#       varstash::autostash PATH=/something/else
#
#   If you run stash, unstash, or varstash interactively, they will instruct
#   you on how to create smartcd scripts for performing those actions
#   automatically.  You can affect this behavior with several variables:
#
#     VARSTASH_QUIET       - Set if you'd rather not see these notices
#
#     VARSTASH_AUTOCONFIG  - Set if you want the suggested actions to be
#                            performed automatically
#
#     VARSTASH_AUTOEDIT   - Set if you want it to set the values, but also
#                           give you an opportunity to edit the file
#
#   If you attempt to stash the same value twice, a warning will be displayed
#   and the second stash will not occur.  To make it happen anyway, pass -f
#   as the first argument to stash.
#
#       $ varstash::stash FOO
#       $ varstash::stash FOO
#       You have already stashed FOO, please specify "-f" if you want to overwrite another stashed value
#       $ varstash::stash -f FOO
#       $
#
#   This rule is a bit different if you are assigning a value and the variable
#   has already been stashed.  In that case, the new value will be assigned, but
#   the stash will not be overwritten.  This allows for non-conflicting chained
#   stash-assign rules.
#
################################################################################

function varstash::stash() {
    if [[ $1 == "-f" ]]; then
        local force=1; shift
    fi

    while [[ -n $1 ]]; do
        if [[ $1 == "alias" && $2 == *=* ]]; then
            shift
            local _stashing_alias_assign=1
            continue
        fi

        local stash_expression=$1
        local stash_which=${stash_expression%%'='*}
        local stash_name=$(varstash::_mangle_var $stash_which)

        # Extract the value and make it double-quote safe
        local stash_value=${stash_expression#*'='}
        stash_value=${stash_value//\\/\\\\}
        stash_value=${stash_value//\"/\\\"}
        stash_value=${stash_value//\`/\\\`}
        stash_value=${stash_value//\$/\\\$}

        if [[ ( -n "$(eval echo '$__varstash_alias__'$stash_name)"    ||
                -n "$(eval echo '$__varstash_function__'$stash_name)" ||
                -n "$(eval echo '$__varstash_array__'$stash_name)"    ||
                -n "$(eval echo '$__varstash_export__'$stash_name)"   ||
                -n "$(eval echo '$__varstash_variable__'$stash_name)" ||
                -n "$(eval echo '$__varstash_nostash__'$stash_name)" )
                && -z $force ]]; then

            if [[ -z $already_stashed && ${already_stashed-_} == "_" ]]; then
                local already_stashed=1
            else
                already_stashed=1
            fi

            if [[ $stash_which == $stash_expression ]]; then
                if [[ -z $run_from_smartcd ]]; then
                    echo "You have already stashed $stash_which, please specify \"-f\" if you want to overwrite another stashed value"
                fi

                # Skip remaining work if we're not doing an assignment
                shift
                continue
            fi
        fi

        # Handle any alias that may exist under this name
        if [[ -z $already_stashed ]]; then
            local alias_def="$(eval alias $stash_which 2>/dev/null)"
            if [[ -n $alias_def ]]; then
                alias_def=${alias_def#alias }
                alias_def=$(echo "$alias_def" | sed 's/"/\\&/g') # Escape double quotes
                eval "__varstash_alias__$stash_name=\"$alias_def\""
                local stashed=1
            fi
        fi
        if [[ $stash_which != $stash_expression && -n $_stashing_alias_assign ]]; then
            eval "alias $stash_which=\"$stash_value\""
        fi

        # Handle any function that may exist under this name
        if [[ -z $already_stashed ]]; then
            local function_def="$(declare -f $stash_which)"
            if [[ -n $function_def ]]; then
                # make function definition quote-safe.  because we are going to evaluate the
                # source with "echo -e", we need to double-escape the backslashes (so 1 -> 4)
                function_def=${function_def//\\/\\\\\\\\}
                function_def=${function_def//\"/\\\"}
                function_def=${function_def//\`/\\\`}
                function_def=${function_def//\$/\\\$}
                eval "__varstash_function__$stash_name=\"$function_def\""
                local stashed=1
            fi
        fi

        # Handle any variable that may exist under this name
        local vartype="$(declare -p $stash_which 2>/dev/null)"
        if [[ -n $vartype ]]; then
            if [[ -n $ZSH_VERSION ]]; then
                local pattern="typeset"
            else
                local pattern="declare"
            fi
            if [[ $vartype == $pattern" -a"* ]]; then
                # varible is an array
                if [[ -z $already_stashed ]]; then
                    eval "__varstash_array__$stash_name=(\"\${$stash_which""[@]}\")"
                fi

            elif ([[ -n $ZSH_VERSION ]] && [[ $vartype == "export "* ]]) \
                || [[ $vartype == $pattern" -x"* ]]; then
                # variable is exported
                if [[ -z $already_stashed ]]; then
                    eval "__varstash_export__$stash_name=\"\$$stash_which\""
                fi
                if [[ $stash_which != $stash_expression && -z $_stashing_alias_assign ]]; then
                    eval "export $stash_which=\"$stash_value\""
                fi
            else
                # regular variable
                if [[ -z $already_stashed ]]; then
                    eval "__varstash_variable__$stash_name=\"\$$stash_which\""
                fi
                if [[ $stash_which != $stash_expression && -z $_stashing_alias_assign ]]; then
                    eval "$stash_which=\"$stash_value\""
                fi

            fi
            local stashed=1
        fi

        if [[ -z $stashed ]]; then
            # Nothing in the variable we're stashing, but make a note that we stashed so we
            # do the right thing when unstashing.  Without this, we take no action on unstash

            # Zsh bug sometimes caues
            # (eval):1: command not found: __varstash_nostash___tmp__home_dolszewski_src_smartcd_RANDOM_VARIABLE=1
            # fixed in zsh commit 724fd07a67f, version 4.3.14
            if [[ -z $already_stashed ]]; then
                eval "__varstash_nostash__$stash_name=1"
            fi

            # In the case of a previously unset variable that we're assigning too, export it
            if [[ $stash_which != $stash_expression && -z $_stashing_alias_assign ]]; then
                eval "export $stash_which=\"$stash_value\""
            fi
        fi

        shift
        unset -v _stashing_alias_assign
    done
}

function varstash::autostash() {
    local run_from_autostash=1
    while [[ -n $1 ]]; do
        if [[ $1 == "alias" && $2 == *=* ]]; then
            shift
            local _stashing_alias_assign=1
        fi

        local already_stashed=
        varstash::stash "$1"
        if [[ -z $already_stashed ]]; then
            local autostash_name=$(varstash::_mangle_var AUTOSTASH)
            local varname=${1%%'='*}
            smartcd::apush $autostash_name "$varname"
        fi
        shift
        unset -v _stashing_alias_assign
    done
}

function varstash::unstash() {
    while [[ -n $1 ]]; do
        local unstash_which=$1
        if [[ -z $unstash_which ]]; then
            continue
        fi

        local unstash_name=$(varstash::_mangle_var $unstash_which)

        # This bit is a little tricky.  Here are the rules:
        #   1) unstash any alias, function, or variable which matches
        #   2) if one or more matches, but not all, delete any that did not
        #   3) if none match but nostash is found, delete all
        #   4) if none match and nostash not found, do nothing

        # Unstash any alias
        if [[ -n "$(eval echo \$__varstash_alias__$unstash_name)" ]]; then
            eval "alias $(eval echo \$__varstash_alias__$unstash_name)"
            unset __varstash_alias__$unstash_name
            local unstashed=1
            local unstashed_alias=1
        fi

        # Unstash any function
        if [[ -n "$(eval echo \$__varstash_function__$unstash_name)" ]]; then
            eval "function $(eval echo -e \"\$__varstash_function__$unstash_name\")"
            unset __varstash_function__$unstash_name
            local unstashed=1
            local unstashed_function=1
        fi

        # Unstash any variable
        if [[ -n "$(declare -p __varstash_array__$unstash_name 2>/dev/null)" ]]; then
            eval "$unstash_which=(\"\${__varstash_array__$unstash_name""[@]}\")"
            unset __varstash_array__$unstash_name
            local unstashed=1
            local unstashed_variable=1
        elif [[ -n "$(declare -p __varstash_export__$unstash_name 2>/dev/null)" ]]; then
            eval "export $unstash_which=\"\$__varstash_export__$unstash_name\""
            unset __varstash_export__$unstash_name
            local unstashed=1
            local unstashed_variable=1
        elif [[ -n "$(declare -p __varstash_variable__$unstash_name 2>/dev/null)" ]]; then
            # Unset variable first to reset export
            unset -v $unstash_which
            eval "$unstash_which=\"\$__varstash_variable__$unstash_name\""
            unset __varstash_variable__$unstash_name
            local unstashed=1
            local unstashed_variable=1
        fi

        # Unset any values which did not exist at time of stash
        local nostash="$(eval echo \$__varstash_nostash__$unstash_name)"
        unset __varstash_nostash__$unstash_name
        if [[ ( -n "$nostash" && -z "$unstashed" ) || ( -n "$unstashed" && -z "$unstashed_alias" ) ]]; then
            unalias $unstash_which 2>/dev/null
        fi
        if [[ ( -n "$nostash" && -z "$unstashed" ) || ( -n "$unstashed" && -z "$unstashed_function" ) ]]; then
            unset -f $unstash_which 2>/dev/null
        fi
        if [[ ( -n "$nostash" && -z "$unstashed" ) || ( -n "$unstashed" && -z "$unstashed_variable" ) ]]; then
            # Don't try to unset illegal variable names
            # Using substitution to avoid using regex, which might fail to load on Zsh (minimal system).
            if [[ ${unstash_which//[^a-zA-Z0-9_]/} == $unstash_which && $unstash_which != [0-9]* ]]; then
                unset -v $unstash_which
            fi
        fi

        shift
    done
}

function varstash::autounstash() {
    # If there is anything in (mangled) variable AUTOSTASH, then unstash it
    local autounstash_name=$(varstash::_mangle_var AUTOSTASH)
    if (( $(smartcd::alen $autounstash_name) > 0 )); then
        local run_from_autounstash=1
        while (( $(smartcd::alen $autounstash_name) > 0 )); do
            local autounstash_var=$(smartcd::afirst $autounstash_name)
            smartcd::ashift $autounstash_name >/dev/null
            varstash::unstash $autounstash_var
        done
        unset $autounstash_name
    fi
}

function varstash::_mangle_var() {
    local mangle_var_where="${varstash_dir:-$PWD}"
    mangle_var_where=${mangle_var_where//[^A-Za-z0-9]/_}
    local mangled_name=${1//[^A-Za-z0-9]/_}
    echo "_tmp_${mangle_var_where}_${mangled_name}"
}

function varstash::_autostashed_var_names() {
    local autostash_name=$(varstash::_mangle_var AUTOSTASH)
    echo "autostashed var names: $(eval "echo \"\${$autostash_name[@]}\"")"
}

# vim: filetype=sh autoindent expandtab shiftwidth=4 softtabstop=4
