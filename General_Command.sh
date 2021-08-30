#!/bin/bash
#docker run -it --rm -v /media/shanto/Entertainment/Austin-Research/Docker/Test:/Scratch detector-wro4j.wro4j:latest

SCRIPT_USERNAME="idflakies"; #  awshi2
TOOL_REPO="iDFlakies"; # OR  dt-fixing-tools


if [[ $1 == "" ]]; then
    echo "arg1 - GitHub SLUG"
   exit
fi

slug=$1;
iDFlakiesVersion=1.1.0; # 1.2.0-SNAPSHOT
timeout=100000;
rounds=10;

modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')

su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/testrunner/ && git pull && /home/$SCRIPT_USERNAME/apache-maven/bin/mvn clean install -B"
su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/$TOOL_REPO/ && git pull && /home/$SCRIPT_USERNAME/apache-maven/bin/mvn clean install -B"

mkdir -p "/Scratch/all-output/${modifiedslug}_output"
chown "$SCRIPT_USERNAME" /Scratch/all-output/${modifiedslug}_output/
chmod 777 /Scratch/all-output/${modifiedslug}_output/

# Set global mvn options for skipping things
MVNOPTIONS="-Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true -fn -B -e"
IDF_OPTIONS="-Ddt.detector.original_order.all_must_pass=false -Ddetector.timeout=${timeout} -Ddt.randomize.rounds=${rounds} -fn -B -e -Ddt.cache.absolute.path=/Scratch/all-output/${modifiedslug}_output"

su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/${slug}; /home/$SCRIPT_USERNAME/apache-maven/bin/mvn clean install ${MVNOPTIONS}"

su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/${slug}; /home/$SCRIPT_USERNAME/$TOOL_REPO/pom-modify/modify-project.sh . $iDFlakiesVersion"

# Optional timeout... In practice our tools really shouldn't need 1hr to parse a project's surefire reports.
su - "$SCRIPT_USERNAME" -c "timeout 1h /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Dtestplugin.className=edu.illinois.cs.dt.tools.utility.ModuleTestTimePlugin -fn -B -e -Ddt.cache.absolute.path=/Scratch/all-output/${modifiedslug}_output |& tee module_test_time.log"




# Run the plugin, random class first, method second
echo "*******************iDFLAKIES************************"
echo "Running testplugin for randomizemethods"
date

su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/${slug}; /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} ${IDF_OPTIONS}" |& tee random_class_method.log



# Change permissions of results and copy outside the Docker image (assume outside mounted under /Scratch)
mkdir -p "/Scratch/all-output/${modifiedslug}_output/misc-output/"
cp -r random_class_method.log "/Scratch/all-output/${modifiedslug}_output/misc-output/"
cp -r module_test_time.log "/Scratch/all-output/${modifiedslug}_output/misc-output/"
chown -R $(id -u):$(id -g) /Scratch/all-output/${modifiedslug}_output/
chmod -R 777 /Scratch/all-output/${modifiedslug}_output/


#su - "$SCRIPT_USERNAME" -c "cd .."

#docker run -t --rm -v /media/shanto/Entertainment/Austin-Research/Docker/Test:/Scratch detector-kevinsawicki.http-request:latest /bin/bash -x /Scratch/General_Command.sh dataset/kevinsawicki.http-request.csv lib

