#!/bin/bash

source ./common.sh
app_name=mongodb

check_root

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

print_time