#!/bin/bash

if [[ $1 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha"
    exit
fi

projfile=$1;

#Project_Data_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
#echo Project_Data_DIR;


# For each project,
for line in $(cat ${projfile}); do
	# Create the corresponding Dockerfile
	slug=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-2 | rev)
	#echo "TEST $slug"
	
	modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')
	#echo $modifiedslug;

	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
	#echo "SCRIPT_DIR= $SCRIPT_DIR ";

	image=detector-${modifiedslug}:latest
	#echo $image;

	# Run the Docker image if it exists
       docker inspect ${image} > /dev/null 2>&1
	    if [ $? == 1 ]; then
		echo "${image} NOT BUILT PROPERLY, LIKELY TESTS FAILED"
	    else
	    	#su - "$SCRIPT_USERNAME" -c "bash General_Command.sh"
	    	#docker run ... "/bin/bash -x /Scratch/other_script.sh ..." 
		docker run -it --rm -v ${SCRIPT_DIR}:/Scratch ${image} /bin/bash -x /Scratch/General_Command.sh ${slug} 
	   fi
done

#bash Initial_create.sh dataset/kevinsawicki.http-request.csv
#bash Initial_create.sh dataset/wro4j.wro4j.csv
#bash Initial_create.sh dataset/tootallnate.java-websocket.csv
