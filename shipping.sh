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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding System user Roboshop"
else
    echo $Y "System user Roboshop already Exits... Skipping" $N
fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downlaoding Shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping"

cd /app 
mvn clean package &>>$LOG_FILE
VALIDATE $? "Packing the shipping Application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and Renaming the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload" 

systemctl enable shipping &>>$LOG_FILE
systemctl start shipping  &>>$LOG_FILE
VALIDATE $? "Starting the shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.dontgiveup.space -u root -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]
then
    mysql -h mysql.dontgiveup.space -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.dontgiveup.space -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.dontgiveup.space -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo $Y "Data is already loaded in to mysql.... SKIPPING" $N
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting Shipping"