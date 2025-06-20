#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)    # $0 -> have the script name
mkdir -p $LOGS_FOLDER
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

echo "Script started executing at : $(date)" &>>$LOG_FILE

check_root(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    else
        echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
    fi
}


# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS" $N | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE" $N | tee -a $LOG_FILE
        exit 1
    fi
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling default nodejs"
    
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs:20"
    
    dnf install nodejs -y  &>>$LOG_FILE
    VALIDATE $? "Installing nodejs:20"

    npm install &>>$LOG_FILE
    VALIDATE $? "Installing NPM"
}

app_setup(){
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Adding System user Roboshop"
    else
        echo -e "System user Roboshop already Exits... $Y Skipping $N"
    fi

    mkdir -p /app  &>>$LOG_FILE
    VALIDATE $? "Creating app directory"
    
    rm -rf /app/*
    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip  &>>$LOG_FILE
    
    cd /app 
    unzip /tmp/$app_name.zip  &>>$LOG_FILE
    VALIDATE $? "Downloading dependencies"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service &>>$LOG_FILE
    VALIDATE $? "Copying $app_name service"

    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $app_name &>>$LOG_FILE
    systemctl start $app_name &>>$LOG_FILE
    VALIDATE $? "Starting $app_name service"
}

print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo -e "Script Executed Successfully, $Y Time taken : $TOTAL_TIME seconds $N"
}