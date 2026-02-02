#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
C="\e[36m"
M="\e[35m"
N="\e[0m"

SCRIPT_DIR=$(pwd)
USER_ID=$(id -u)
LOG_FOLDER="/var/log/Roboshop-Again-logs"
LOG_FILE="${LOG_FOLDER}/$0.log"
MONGO_HOST="mongodb.opsora.space"

mkdir -p ${LOG_FOLDER}

if [ ${USER_ID} -ne 0 ]; then
   echo -e " $R User is not a Root use. Kindly run the code as a Root use... $N" | tee -a $LOG_FILE
   exit 1
else
   echo -e "$G yes you're a Root user. Welcome:) $N" | tee -a $LOG_FILE
   continue
fi

VALIDATE(){
    if [ $1 -ne 0 ];then
      echo -e "$R $2 is unsuccesfull..." &>> ${LOG_FILE}
    else
      echo -e "$G $2 is successfull..." &>> ${LOG_FILE}
    fi

}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs 20 version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs 20 version"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ];then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating system user"
else
  echo -e "$G User does exist.. Skipping Creation $N"
fi

mkdir -p /app
VALIDATE $? "Creating APP Directory."

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Application code."

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the Code"
 
npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Starting and enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE

mongosh --host ${MONGO_HOST} </app/db/master-data.js
VALIDATE $? "Loading products"

systemctl restart catalogue &>>$LOG_FILE

VALIDATE $? "Restarting Catalogue" 

systemctl status catalogue &>>$LOG_FILE
VALIDATE $? "Checking catalogue status" 