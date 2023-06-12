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
```
Настройка mariadb
```bash
mysql_secure_installation # запуск внутри контейнера
```

## Настройка nginx
Конфиг nginx
в нем прописываем где брать конфиги сайтов
```
/etc/nginx.nginx.conf
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
