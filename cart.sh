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

if [ ${USER_ID} -ne 0 ]; then
   echo -e " $R User is not a Root use. Kindly run the code as a Root use... $N" | tee -a $LOG_FILE
   exit 1
else
   echo -e "$G yes you're a Root user. Welcome:) $N" | tee -a $LOG_FILE
   continue
fi

mkdir -p ${LOG_FOLDER}

VALIDATE(){
    if [ $1 -ne 0 ];then
      echo -e "$R $2 is unsuccesfull..." &>> ${LOG_FILE}
    else
      echo -e "$G $2 is successfull..." &>> ${LOG_FILE}
    fi

}

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs 20 version"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs 20 version"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ];then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating system user"
else
  echo -e "$G User does exist.. $Y Skipping Creation $N"
fi

mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating APP Directory."

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Application code."

cd /app &>> $LOG_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the Code"
 
npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Created systemctl service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading Daemon cart."

systemctl enable cart  &>>$LOG_FILE
VALIDATE $? "enabling cart"

systemctl start cart  &>>$LOG_FILE
VALIDATE $? "Starting cart"