#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"

LOG_FILE=$(echo $0 | cut -d "." -f1)

TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)

LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2....$R FAILURE $N"
        exit 1
    else 
        echo -e "$2....$G SUCCESS $N"
    fi         
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
then 
    echo "you are normal user. you cannot install. please exit."
    exit 1
fi 
}

echo "Script started executing at:$TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT 

dnf module disable nodejs -y &>>$LOG_FILE_NAME
 VALIDATE $? "Disabling existing default nodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nodejs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodaJS"

useradd expense &>>$LOG_FILE_NAME
VALIDATE $? "creating expense user"

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app
 
unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing Dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#prepare mysql schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL Client"

mysql -h mysql.deepthi.tech -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting backend"

