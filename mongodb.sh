#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
C="\e[36m"
M="\e[35m"
N="\e[0m"

SCRIPT_DIR=${pwd}
USER_ID=$(id -u)
LOG_FOLDER="/var/log/Roboshop-Again-logs"
LOG_FILES="${LOG_FOLDER}/$0.log"


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
      echo -e "$R $2 is unsuccesfull..." &>>${LOG_FILE}
    else
      echo -e "$G $2 is successfull..." &>>${LOG_FILE}
    fi

}
  
dnf install mongodb-org -y &>>${LOG_FILE}
VALIDATE $? "Installing MongoDB Server"

systemctl enable mongod &>>${LOG_FILE}
systemctl start mongod 
VALIDATE $? "Enabling and starting mongodb service."

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf


systemctl restart mongod &>>${LOG_FILE}
VALIDATE $? "Restaring mongodb service"
