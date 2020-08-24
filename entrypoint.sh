#!/bin/bash

echo "Repository: [$GITHUB_REPOSITORY]"

# log inputs
echo "Inputs"
echo "---------------------------------------------"
REPO_TYPE="$INPUT_TYPE"
FILE_PATH="$INPUT_PATH"
GITHUB_TOKEN="$INPUT_TOKEN"
echo "Repo type    : $REPO_TYPE"
FILES=($RAW_FILES)
echo "Path         : $FILE_PATH"

# set temp path
TEMP_PATH="/ghars/"
cd /
mkdir "$TEMP_PATH"
cd "$TEMP_PATH"
echo "Temp Path       : $TEMP_PATH"
echo "---------------------------------------------"

echo " "

# find username and repo name
REPO_INFO=($(echo $GITHUB_REPOSITORY | tr "/" "\n"))
USERNAME=${REPO_INFO[0]}
REPO_NAME=${REPO_INFO[1]}

# initalize git
echo "Intiializing git"
git config --system core.longpaths true
git config --global core.longpaths true
git config --global user.email "action-bot@github.com" && git config --global user.name "Github Action"
echo "Git initialized"

echo " "

echo "###[group] $REPO_TYPE"

# clone the repo
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
GIT_PATH="${TEMP_PATH}${GITHUB_REPOSITORY}"
echo "Cloning [$REPO_URL] to [$GIT_PATH]"
git clone --quiet --no-hardlinks --no-tags --depth 1 $REPO_URL ${GITHUB_REPOSITORY}

cd $GIT_PATH

# verify path exists
if [ ! test -f "$FILE_PATH" ]; then 
    echo "Path does not exist: [${FILE_PATH}]"
    return
fi

# default parameters
DESCRIPTION=""
WEBSITE=""
TOPICS=""

# determine repo type
if [ "$REPO_TYPE" == "npm" ]; then
    # install jq to parse json
    sudo apt-get update && sudo apt-get -y install jq
    #sudo chmod +x /usr/bin/jq # MAYBE need this

    # read in the description
    DESCRIPTION=`jq '.description' ${FILE_PATH}`
    WEBSITE=`jq '.homepage' ${FILE_PATH}`
    TOPICS=`jq '.keywords' ${FILE_PATH}`

elif [ "$REPO_TYPE" == "nuget" ]
    # TODO
    # read in file and store in variable
    # VALUE=`cat ${FILE_PATH}`
    # echo $VALUE
else
    echo "Unsupported repo type: [${REPO_TYPE}]"
fi

# update the repository with the values that were set
echo "Updating repository [${GITHUB_REPOSITORY}]"
DATA='{"description":"$1","homepage":"$2"}'
curl \
    -X PATCH \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$DATA" -- "$DESCRIPTION" "$WEBSITE" \
    -u ${USERNAME}:${GITHUB_TOKEN} \
    ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}

echo "Updating topics for [${GITHUB_REPOSITORY}]"
curl \
    -X PUT \
    -H "Accept: application/vnd.github.mercy-preview+json" \
    -u ${USERNAME}:${GITHUB_TOKEN} \
    -d '{"names":["temp"]}' \
    ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/topics