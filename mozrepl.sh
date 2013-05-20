## mozrepl.sh
## 2012/08/14

## Source this (don't call it) to provide bash with a suite of functions for
## driving the MozREPL extension.

## Original found at:
## http://philippe.cassignol.pagesperso-orange.fr/2012/mozrepl.sh

## Short French-English lexicon at end


# Enable (1) or disable (0) diagnostic output
moz__DEBUG=0

moz__mktemp_gnu () { # $1: mktemp binary name (mktemp or gmktemp) $2: template
    "$1" --tmpdir "${2}.XXX"
}

moz__mktemp_bsd () { # $1: template
    mktemp -t "$1"
}

moz__mktemp () { # $1: template
    case "$OSTYPE" in

        [Dd]arwin*|*BSD)
            # Do we have the GNU mktemp installed anywhere on PATH?
            if [ -x "`which gmktemp`" ] ; then
                moz__mktemp_gnu gmktemp $@
            else
                moz__mktemp_bsd $@
            fi
            ;;

        *)
            moz__mktemp_gnu mktemp $@
            ;;

    esac
}

moz_cmd () { # $1: commande javascript
expect <<EOF
    spawn  nc localhost 4242
    expect "repl>"; send "$*\r"
    expect "repl>"; send "repl.quit()\r"
EOF
}


moz_script () { # $1: URL d'un fichier javascript
expect <<EOF
    log_user 0
    spawn  nc localhost 4242
    expect "repl>"; send "repl.enter(content)\r"
    expect "repl>"; log_user 1; send "repl.load(\"$1\")\r"
    expect "repl>"; send "repl.quit()\r"
EOF
}

moz_getURL () { # $1: URL
    moz_cmd "content.location.href = '$1'"
}


moz_waitURL () {  # $1: URL
    while ! moz_cmd "repl.print(content.location.href)" | grep "$1"
    do
        echo "WAIT URI: $1" >&2
        sleep 1
    done
    sleep 1
}


moz_findLinks () { # $1: texte du lien
    local FIND_LINKS="`moz__mktemp findLinks`"
    (( ${moz__DEBUG:-0} )) && echo "FIND_LINKS: $FIND_LINKS" >&2
cat > "$FIND_LINKS" <<EOF

    var exp = new RegExp("$1");

    for ( var i=0; i<document.links.length; i++ ) {
        if ( exp.test( document.links[i].text ) )     // repl.print(content.location.href)"
            repl.print( document.links[i].href );
    }

EOF
    (( ${moz__DEBUG:-0} )) && echo Wrote file >& 2
    moz_script "file://${FIND_LINKS}" | sed '/^file|^http/ s/\r//g'
}


moz_setInput () { # $1: nom  $2: valeur
    local SET_INPUT="`moz__mktemp setInput`"
cat > "$SET_INPUT" <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]
                                                          // [object HTMLInputElement] .type=text .name=q .value=Shakira
    for ( var i=0; i<c.length; i++ ) {
        if ( c[i].type == "text" || c[i].type == "password" )
            if ( c[i].name == "$1") {
                c[i].value = "$2";
            }
    }

EOF
    moz_script "file://${SET_INPUT}"
}


moz_submitFormByName () { # $1: nom formulaire
    local SUBMIT_FORM="`moz__mktemp submitForm`"
cat > "$SUBMIT_FORM" <<EOF

    var c = this.document.getElementsByTagName("form");

    for ( var i=0; i<c.length; i++ ) {
        if ( c[i].name == "$1" )
            c[i].submit();
    }
EOF
    moz_script "file://${SUBMIT_FORM}"
}


moz_setTextArea () { # $1: nom  $2: valeur
    local SET_TEXT_AREA="`moz__mktemp setTextArea`"
cat > "$SET_TEXT_AREA" <<EOF

    var c = this.document.getElementsByTagName("textarea");  // [object HTMLCollection]
                                                             // [object HTMLTextAreaElement] type name value
    for ( var i=0; i<c.length; i++ )
        if ( c[i].name == "$1")
            c[i].value = "$2";

EOF
    moz_script "file://${SET_TEXT_AREA}"
}


moz_setSelect () { # $1: nom $2: valeur
    local SET_SELECT="`moz__mktemp setSelect`"
cat > "$SET_SELECT" <<EOF

    var c = this.document.getElementsByTagName("select");  // [object HTMLCollection]
                                                           // [object HTMLSelectElement]
    for ( var i=0; i<c.length; i++ )
        if ( c[i].name == "$1")
            c[i].value = "$2";

EOF
    moz_script "file://${SET_SELECT}"
}


moz_setInputRadio () { # $1: nom $2: valeur
    local SET_INPUT_RADIO="`moz__mktemp setInputRadio`"
cat > "$SET_INPUT_RADIO" <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]

    for ( var i=0; i<c.length; i++ ) {                    // [object HTMLInputElement]

         if (  c[i].type == "radio" && c[i].name == "$1" && c[i].value == "$2" )
              c[i].checked = true;

    }
EOF
    moz_script "file://${SET_INPUT_RADIO}"
}


moz_waitTitle () {  # $1: URL
    while ! moz_cmd "repl.print( document.title )" | tail -n 2 | grep "$1"
    do
        echo "WAIT Title: $1" >&2
        sleep 1
    done
    sleep 1
}


moz_listSelectValues () { # $1: nom
    local LIST_SELECT_VALUES="`moz__mktemp listSelectValues`"
cat > "$LIST_SELECT_VALUES" <<EOF

    var c = this.document.getElementsByTagName("select");  // [object HTMLCollection]
                                                           // [object HTMLSelectElement]
    for ( var i=0; i<c.length; i++ )
        if ( c[i].name == "$1") {
            c = c[i].options;                              // [object HTMLCollection]

            for ( var i=0; i<c.length; i++ ) {             // [object HTMLOptionElement]
               repl.print( "VALUE\t" + c[i].value + "\t" + c[i].textContent );
            }
            break;
        }

EOF
    moz_script "file://${LIST_SELECT_VALUES}" | \
    sed '/^VALUE\s+/ s/^VALUE\t//; s/\r//g; /^\s*$/d'
}


moz_getInput () { # $1: nom
    local GET_INPUT="`moz__mktemp getInput`"
cat > "$GET_INPUT" <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]
                                                          // [object HTMLInputElement] .type=text .name=q .value=Shakira
    for ( var i=0; i<c.length; i++ ) {

        if ( c[i].type == "text" || c[i].type == "password" || c[i].type == "hidden" )
            if ( c[i].name == "$1")
                repl.print( "VALUE\t" + c[i].value );
    }

EOF
    moz_script "file://${GET_INPUT}" | \
    sed '/^VALUE\s+/ s/^VALUE\t//; s/\r//g; /^\s*$/d'
}


moz_setInputCheckbox () { # $1: nom $2: valeur
    local SET_INPUT_CHECKBOX="`moz__mktemp setInputCheckbox`"
cat > "$SET_INPUT_CHECKBOX" <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]

    for ( var i=0; i<c.length; i++ ) {                    // [object HTMLInputElement]

         if (  c[i].type == "checkbox" && c[i].name == "$1" )
              c[i].checked = $2;

    }
EOF
    moz_script "file://${SET_INPUT_CHECKBOX}"
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test

# moz_setInputCheckbox "typeTravailleur" 1

# moz_setInput "valeurSalMensuBrut" 1400

# moz_getInput "page"

# moz_listSelectValues "natureVoie"

# moz_waitTitle "D.claration"

# moz_setInputRadio "sexe" "1"

# moz_cmd "repl.doc(repl.inspect); repl.print(content.location.href)"

# moz_get "https://monespaceprive.msa.fr/enligne/Menu/ChoixRessource.do?reqCode=execute&id=1690611069043|43143617900011"

# moz_wait "http://www.google.fr"

# moz_submitFormByName "authentification"

# url=$(moz_findLinks "Solution" | sed -n 1p)
# moz_get "$url"

# moz_setTextArea "adresse" "Marcel Pagnol\nMarseille"

# moz_setInput "identifiant" "Marcel"


## Lexicon

# fichier    : file
# nom        : name (or key)
# valeur     : value
# commande   : command
# d'un       : of a(n)
# texte      : text
# lien       : link
# du         : of the
# formulaire : of the/a form
