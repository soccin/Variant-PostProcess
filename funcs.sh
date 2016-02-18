
function getHaplotypeVCF {

    PIPEOUT=$1

    HAPLOTYPEVCF="_ERROR"
    if [ -e $PIPEOUT/variants/haplotypecaller ]; then

        HAPLOTYPEVCF=$(ls $PIPEOUT/variants/haplotypecaller/*_HaplotypeCaller.vcf)

    elif [ -e $PIPEOUT/variants/snpsIndels/haplotypecaller ]; then

        HAPLOTYPEVCF=$(ls $PIPEOUT/variants/snpsIndels/haplotypecaller/*_HaplotypeCaller.vcf)

    else

        echo FATAL ERROR Unknown pipeline output directory format
        exit -1

    fi


    if [ "$HAPLOTYPEVCF" == "_ERROR" ]; then

        echo
        echo FATAL ERROR Can not find Haplotype file in directory
        echo $PIPEOUT/variants/haplotypecaller
        echo
        exit -1

    fi

    echo "$HAPLOTYPEVCF"

}

function getMutectDir {

    PIPEOUT=$1
    if [ -e $PIPEOUT/variants/mutect ]; then
        MUTECTDIR=$PIPEOUT/variants/mutect
    elif [ -e $PIPEOUT/variants/snpsIndels/mutect ]; then
        MUTECTDIR=$PIPEOUT/variants/snpsIndels/mutect
    else
        echo FATAL ERROR Unknown pipeline output directory format
        exit -1
    fi

    echo "$MUTECTDIR"

}