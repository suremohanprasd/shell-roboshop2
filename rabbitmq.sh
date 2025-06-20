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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Copying of RabbitMQ"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "Satrting the rabbitmq server"

rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"  &>>$LOG_FILE
VALIDATE $? "Setting permissions to roboshop user"