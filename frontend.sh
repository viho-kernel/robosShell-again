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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y &>>$LOG_FILE
dnf install nginx -y

VALIDATE $? "Downloading and installing Nginx service"

systemctl enable nginx &>>$LOG_FILE

systemctl start nginx 
VALIDATE $? "Enabling and starting the Nginx service"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing Default HTML Conent"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> ${LOG_FILE}
VALIDATE $? "Downloading Code"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend"

cp $SCRIPT_DIR/frontend.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "CREATING Reverse Proxy"

systemctl restart nginx 
VALIDATE $? "Restarting Catalogue" 

systemctl status nginx &>>$LOG_FILE
VALIDATE $? "Checking nginx status" 