# nginx
1) С помощью terraform ставим сервер
2) Добавляем метки для ansible
```tf
  labels = {
    ansible_group = "nginx"  # можем определить labels по ним будет работать ansible
    env           = "learn"
  }
```
3) Заполняем файлы в каталоге ansible: ansible.cfg nginx.yaml inventory.gcp.yml
4) Ставим nginx с помощью ansible
```bash
ansible all -m ping
ansible all -m shell -a "uptime"
ansible-playbook nginx.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```
5) Ставим docker
```bash
ansible-playbook docker.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```
6) Ставим mariadb
```bash
ansible-playbook mariadbdocker.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```

7) Проверяем что mariadb работает на хосте
```bash
docker ps
docker logs wp_database
docker exec -it wp_database bash
mysql -u root -p
SELECT VERSION();
```
```bash
docker stop $(docker ps -a -q) # остановить все запущенные контейнеры
docker rm $(docker ps -a -q) # удалить все незапущенные контейнеры
docker rmi $(docker images -q) # удалить все образы
```

## Mariadb commands
```bash
# Посмотреть плагины
SHOW PLUGINS;
# Посмотреть есть ли анонимные пользователи
SELECT User, Host FROM mysql.user WHERE User = '';
# Посмотреть базы
SHOW DATABASES;
# Посмотреть способы подключения к базе
SELECT user,authentication_string,plugin,host FROM mysql.user;
# Если у нас plugin auth_socket то можем поменять на mysql_native_password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'our_very_strong_passsword';
# Посмотреть таблицу с пользователями
SELECT User, Host, Password FROM mysql.user;
# Дать возможность подключаться с помощью root извне.
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'ВАШ_НОВЫЙ_ПАРОЛЬ' WITH GRANT OPTION;
```
```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

Настройка mariadb
```bash
mysql_secure_installation # запуск внутри контейнера
```

## Настройка nginx
Конфиг nginx
в нем прописываем где брать конфиги сайтов
```
/etc/nginx/nginx.conf
```

Где находится дефолт конфиг сайта
```
/etc/nginx/conf.d/default.conf
```

```conf
server {
    # На каком порту nginx будет слушать
    listen       80;
    # Здесь прописываем доменное имя нашего сервера
    server_name nginx.basov.world;

    #access_log  /var/log/nginx/host.access.log  main;

    # Локация где хранится сайт можем добавим index.php
    location / {
        root   /usr/share/nginx/html;
        index index.php index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm.sock
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
        fastcgi_intercept_errors on;
        fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        include        fastcgi_params;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    location ~ /\.ht {
        deny  all;
    }
}

```

### Просмотр Errors
```bash
cat /var/log/nginx/error.log
```

### Просмотр конфига без комментариев
```bash
cat /etc/php/7.4/fpm/pool.d/www.conf | egrep -Ev "^\s*(;|#|$)"
```

### Просмотр под каким пользователем работает nginx
```bash
ps aux | grep nginx
# www-data  1234  0.0  0.1  12345  6789 ?        S    Jun10   0:00 nginx: worker process
```

### У сервера nginx должны быть права на php7.4-fpm.sock иначе ничего обрабатываться не будет 
```
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
```

### Устанавливает значение переменной окружения SCRIPT_FILENAME для передачи в FastCGI-сервер. Переменная окружения SCRIPT_FILENAME ### представляет путь к запрашиваемому скрипту php на файловой системе сервера. Чтобы не было ошибки file not found нужно 
### root   /usr/share/nginx/html; помещать в секцию server или менять $document_root$fastcgi_script_name
```
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
```

# Install php myadmin
```bash
apt-get update
apt-get install phpmyadmin
```
```
Configuration phpmyadmin
Нажимаем tab для отмены выбора apache потому что мы используем nginx
```
```
Configuring phpadmin
Нажимаем No если mariadb в контейнере.
```

Вносим в конфиг наш сервер mariadb в docker контейнере
```bash
nano /etc/phpmyadmin/config.inc.php
```
Добавляем конфигурацию перед
/*
 * End of servers configuration
 */

```
/**
 * First server
 */
$i++;

$cfg['Servers'][$i]['host'] = '127.0.0.1'; // Замените 'localhost' на IP-адрес или имя хоста базы данных
$cfg['Servers'][$i]['port'] = '3306'; // Убедитесь, что порт соответствует порту базы данных
```

Делаем линк phpadmin в каталог сайтов nginx
```bash
ln -s /usr/share/phpmyadmin /var/www/html
```
Команда phpenmod mcrypt используется для включения расширения mcrypt в PHP.
Расширение mcrypt предоставляет функциональность для шифрования и дешифрования данных в PHP. Оно включает различные алгоритмы шифрования, такие как AES, DES, Blowfish и другие.
```bash
phpenmod mcrypt
```

Перезапускаем
```
systemctl restart php7.4-fpm
```
Заходим
https://nginx.basov.world/phpmyadmin/index.php

Роль ansible phpmyadmin делает тоже

## Делаем дополнительную защиту для phpmyadmin
меняем имя каталога /var/www/html/phpmyadmin на нестандартное

Генерируем шифрованный пароль с помощью openssl для добавления этого пароля в nginx
```bash
openssl passwd
```
или с помощью apache2-utils (добаляем пароль для пользователя user)
```bash
htpasswd -c /etc/nginx/.htpasswd user
```
Далее нужно прописать эти настройки в конфигурации сайта nginx чтобы был парольный вход
```
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/.htpasswd;
```

## Устанавливаем wordpress

Готовим базу данных
```sql
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci
```

Или меняем если база уже создана
```sql
USE wordpress;
ALTER DATABASE wordpress
CHARACTER SET utf8
COLLATE utf8_unicode_ci;
```
Посмотреть текущие значения
```sql
SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'wordpress';
```
Даем права пользователю к базе
```sql
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
```
Меняем пароль пользователю
```sql
ALTER USER 'wordpress'@'%' IDENTIFIED BY 'really_strong_password';
```
