## mozrepl.sh
## 2012/08/14

## Source this (don't call it) to provide bash with a suite of functions for
## driving the MozREPL extension.

## Original found at:
## http://philippe.cassignol.pagesperso-orange.fr/2012/mozrepl.sh

## Short French-English lexicon at end

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

cat > /tmp/findLinks.js <<EOF

    var exp = new RegExp("$1");

    for ( var i=0; i<document.links.length; i++ ) {
        if ( exp.test( document.links[i].text ) )     repl.print(content.location.href)"
            repl.print( document.links[i].href );
    }

EOF
    moz_script file:///tmp/findLinks.js | grep "^file\|^http" | sed -e 's/\r//g'
}


moz_setInput () { # $1: nom  $2: valeur

cat > /tmp/setInput.js <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]
                                                          // [object HTMLInputElement] .type=text .name=q .value=Shakira
    for ( var i=0; i<c.length; i++ ) {
        if ( c[i].type == "text" || c[i].type == "password" )
            if ( c[i].name == "$1") {
                c[i].value = "$2";
            }
    }

EOF
    moz_script file:///tmp/setInput.js
}


moz_submitFormByName () { # $1: nom formulaire

cat > /tmp/submitForm.js <<EOF

    var c = this.document.getElementsByTagName("form");

    for ( var i=0; i<c.length; i++ ) {
        if ( c[i].name == "$1" )
            c[i].submit();
    }
EOF
    moz_script file:///tmp/submitForm.js

}


moz_setTextArea () { # $1: nom  $2: valeur

cat > /tmp/setTextArea.js <<EOF

    var c = this.document.getElementsByTagName("textarea");  // [object HTMLCollection]
                                                             // [object HTMLTextAreaElement] type name value
    for ( var i=0; i<c.length; i++ )
        if ( c[i].name == "$1")
            c[i].value = "$2";

EOF
    moz_script file:///tmp/setTextArea.js
}


moz_setSelect () { # $1: nom $2: valeur

cat > /tmp/setSelect.js <<EOF

    var c = this.document.getElementsByTagName("select");  // [object HTMLCollection]
                                                           // [object HTMLSelectElement]
    for ( var i=0; i<c.length; i++ )
        if ( c[i].name == "$1")
            c[i].value = "$2";

EOF
    moz_script file:///tmp/setSelect.js
}


moz_setInputRadio () { # $1: nom $2: valeur

cat > /tmp/setInputRadio.js <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]

    for ( var i=0; i<c.length; i++ ) {                    // [object HTMLInputElement]

         if (  c[i].type == "radio" && c[i].name == "$1" && c[i].value == "$2" )
              c[i].checked = true;

    }
EOF
    moz_script file:///tmp/setInputRadio.js
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

cat > /tmp/listSelectValues.js <<EOF

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
    moz_script file:///tmp/listSelectValues.js | grep "^VALUE  " | sed 's/^VALUE\t//; s/\r//g; /^\s*$/d'
}


moz_getInput () { # $1: nom

cat > /tmp/getInput.js <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]
                                                          // [object HTMLInputElement] .type=text .name=q .value=Shakira
    for ( var i=0; i<c.length; i++ ) {

        if ( c[i].type == "text" || c[i].type == "password" || c[i].type == "hidden" )
            if ( c[i].name == "$1")
                repl.print( "VALUE\t" + c[i].value );
    }

EOF
    moz_script file:///tmp/getInput.js | grep "^VALUE	" | sed 's/^VALUE\t//; s/\r//g; /^\s*$/d'
}


moz_setInputCheckbox () { # $1: nom $2: valeur

cat > /tmp/setInputCheckbox.js <<EOF

    var c = this.document.getElementsByTagName("input");  // [object HTMLCollection]

    for ( var i=0; i<c.length; i++ ) {                    // [object HTMLInputElement]

         if (  c[i].type == "checkbox" && c[i].name == "$1" )
              c[i].checked = $2;

    }
EOF
    moz_script file:///tmp/setInputCheckbox.js
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
