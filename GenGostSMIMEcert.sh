#!/bin/bash
#set -x

pki_path=./
pfx_pass=123

cd $pki_path

function set_algorithm {

  echo 'Выберите алгоритм:'
  echo 'Введите цифру "1" для выбора алгоритма RSA'
  echo 'Введите цифру "2" для выбора алгоритма GOST'
  read -p "Выбор: " choise
  case $choise in
    1)
      echo 'Выбран алгоритм RSA'
      algorithm=RSA
      ;;
    2)
      echo 'Выбран алгоритм GOST'
      algorithm=GOST
      ;;
    *)
      echo 'Ошибка выбора!'
      exit 1
  esac

}

function gen_rsa_CA {

  if [ ! -f CA_rsa.key ] && [ ! -f CA_rsa.cer ]; then
    echo 'Приватный ключ и сертификат центра сертификации НЕ НАЙДЕНЫ!'
    echo 'Генерация приватного ключа и сертификата центра сертификации...'
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out CA_rsa.key &&
    openssl req -new -x509 -sha256 -days 356 -nodes -key CA_rsa.key -out CA_rsa.cer \
    -subj "/C=RU/ST=Russia/L=SPb/O=Test_org/OU=Test_OU/CN=Test_CA" &&
    echo 'Готово'
  else
    echo 'Найден приватный ключ и сертификат центра сертификации'
  fi

}

function gen_gost_CA {

  if [ ! -f CA_gost.key ] && [ ! -f CA_gost.cer ]; then
    echo 'Приватный ключ и сертификат центра сертификации НЕ НАЙДЕНЫ!'
    echo 'Генерация приватного ключа и сертификата центра сертификации...'
    openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out CA_gost.key &&
    openssl req -new -x509 -md_gost12_256 -days 365 -key CA_gost.key -out CA_gost.cer \
    -subj "/C=RU/ST=Russia/L=SPb/O=Test_org/OU=Test_OU/CN=Test_CA" &&
    echo 'Готово'
  else
    echo 'Найден приватный ключ и сертификат центра сертификации'
  fi

}

function gen_rsa_user_cert {

  read -p "Введите e-mail пользователя: " user_email
  echo "Генерация приватного ключа пользователя $user_email..."
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$user_email"_rsa.key &&
  echo 'Готово'
  echo "Генерация запроса на выдачу сертификата пользователю $user_email..."
  openssl req -new -key "$user_email"_rsa.key -out "$user_email"_rsa.csr -subj "/C=RU/L=SPb/O=Test_org/CN=$user_email/emailAddress=$user_email" &&
  echo 'Готово'
  echo "Выпуск сертификата пользователю $user_email..."
  openssl x509 -req -days 365 -in "$user_email"_rsa.csr -CA CA_rsa.cer -CAkey CA_rsa.key -CAcreateserial -out "$user_email"_rsa.cer &&
  openssl pkcs12 -password pass:$pfx_pass -inkey "$user_email"_rsa.key -in "$user_email"_rsa.cer -export -out "$user_email"_rsa.pfx &&
  echo 'Готово (алгоритм RSA)'

}

function gen_gost_user_cert {

  read -p "Введите e-mail пользователя: " user_email
  echo "Генерация приватного ключа пользователя $user_email..."
  openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out "$user_email"_gost.key &&
  echo 'Готово'
  echo "Генерация запроса на выдачу сертификата пользователю $user_email..."
  openssl req -new  -md_gost12_256 -key "$user_email"_gost.key -out "$user_email"_gost.csr -subj "/C=RU/L=SPb/O=Test_org/CN=$user_email/emailAddress=$user_email" &&
  echo 'Готово'
  echo "Выпуск сертификата пользователю $user_email..."
  openssl x509 -req -days 365 -in "$user_email"_gost.csr -CA CA_gost.cer -CAkey CA_gost.key -CAcreateserial -out "$user_email"_gost.cer &&
  openssl pkcs12 -password pass:$pfx_pass -inkey "$user_email"_gost.key -in "$user_email"_gost.cer -export -out "$user_email"_gost.pfx &&
  echo 'Готово (алгоритм GOST)'

}

function gen_CA {

  if [ $algorithm = RSA ]; then
    gen_rsa_CA
  else
    gen_gost_CA
  fi

}

function gen_user_cert {

  if [ $algorithm = RSA ]; then
    gen_rsa_user_cert
  else
    gen_gost_user_cert
  fi

}

set_algorithm
echo "Генерация S/MIME сертификата по алгоритму $algorithm..."
gen_CA
gen_user_cert
exit 0
