#!/bin/bash

source ./common.sh
app_name=redis
check_root

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disable default redis"

dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "Enable redis:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing redis"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>$LOG_FILE
VALIDATE $? "Editing redis conf file remote connections"


systemctl enable redis  &>>$LOG_FILE
VALIDATE $? "Enabiliing redis"

systemctl start redis  &>>$LOG_FILE
VALIDATE $? "Starting redis"

print_time
