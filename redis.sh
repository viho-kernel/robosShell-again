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

dnf module disable redis -y
dnf module enable redis:7 -y &>>$LOG_FILE
dnf install redis -y
VALIDATE $? "Installing enable the redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' '/protected-mode/c/protected-mode no' /etc/redis/redis.conf

VALIDATE $? "editing redis service"

systemctl enable redis &>>$LOG_FILE

systemctl start redis 
VALIDATE $? "Enabling and starting service"