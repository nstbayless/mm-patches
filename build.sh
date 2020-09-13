# note: asm6f must be on the PATH.
configs=(NO_BOUNCY_LANDINGS NO_AUTO_SCROLL UNITILE)
outs=(no-bouncy-landings no-auto-scroll unitile)
folders=("no-bouncy-landings/" "no-auto-scroll/" "unitile")

name="micro-mages"

export="$name"

if [ -d "$export" ]
then
    rm -r "$export"
fi
mkdir "$export"
cp included-readme.txt $export/README.txt

if [ ! -d "nes" ]
then
    mkdir "nes"
fi

for i in {0..2}
do
    BASE=base.nes
    CONFIG="${configs[$i]}"
    SRC="patch.asm"
    TAG="${outs[$i]}"
    if [ $TAG != "standard" ]
    then
        OUT="$name-$TAG"
    else
        OUT="$name"
    fi
    folder="${folders[$i]}"
    
    if [ ! -f "$BASE" ]
    then
        echo "Base ROM $BASE not found -- skipping."
        continue
    fi
    
    echo
    echo "Producing hacks for $BASE"
    
    mkdir "$export/$folder"
        
    outfile="$OUT"
    
    echo "------------------------------------------"
    echo "generating patch ($outfile) from $BASE"
    chmod a-w "$BASE"
    echo "INCNES \"$BASE\"" > inc-base.asm
    which asm6f > /dev/null
    if [ $? != 0 ]
    then
        echo "asm6f is not on the PATH."
        continue
    fi
    printf 'base size 0x%x\n' `stat --printf="%s" "$BASE"`
    asm6f -c -n -i "-d$CONFIG" "-dUSEBASE" "$SRC" "$outfile.nes"
    
    if [ $? != 0 ]
    then
        exit
    fi
    
    printf 'out size 0x%x\n' `stat --printf="%s" "$outfile.nes"`
    
    if [ $? != 0 ]
    then
        continue
    fi
    
    #continue
    if ! [ -f "$outfile.ips" ]
    then
        echo
        echo "Failed to create $outfile.ips"
        continue
    fi
    echo
    
    # apply ips patch
    chmod a+x flips/flips-linux
    
    if [ -f patch.nes ]
    then
      rm patch.nes
    fi
    
    flips/flips-linux --apply "$outfile.ips" "$BASE" patch.nes
    if ! [ -f "patch.nes" ]
    then
        echo "Failed to apply patch $i."
        continue
    fi
    echo "patch generated."
    md5sum "$outfile.nes"
    
    cmp "$outfile.nes" patch.nes
    if [ $? != 0 ]
    then
        continue
    fi
    
    mv -t nes/ $outfile.nes*
    
    if [ -f patch.nes ]
    then
      rm patch.nes
    fi
    
    mv $outfile.ips "$export/$folder/"
done

echo "============================================"
echo "Assembling export."

if [ -f $name.zip ]
then
  rm $name.zip 2>&1
fi
zip -r $name.zip $export/*