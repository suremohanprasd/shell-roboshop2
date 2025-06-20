#!/bin/bash

R="-e \e[31m"
G="-e \e[32m"
Y="-e \e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)    # $0 -> have the script name
mkdir -p $LOGS_FOLDER
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

echo "Script started executing at : $(date)" &>>$LOG_FILE


USERID=$(id -u)

if [ $USERID -ne 0 ]
then
    echo $R "ERROR:: Please run this script with root access" $N | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo $G "You are running with root access" $N | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo $G "$2 is ... SUCCESS" $N | tee -a $LOG_FILE
    else
        echo $R "$2 is ... FAILURE" $N | tee -a $LOG_FILE
        exit 1
    fi
}

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo  &>>$LOG_FILE
VALIDATE $? "Copying Mongodb repo"

dnf install mongodb-org -y  &>>$LOG_FILE
VALIDATE $? "Installing Mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling Mongodb"

systemctl start mongod  &>>$LOG_FILE
VALIDATE $? "Starting Mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf  &>>$LOG_FILE
VALIDATE $? "Editing MongoDB conf file remote connections"

systemctl restart mongod  &>>$LOG_FILE
VALIDATE $? "Restarting Mongodb"

