
    # настройки для php    
    location ~ \.php$ {
        #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        include fastcgi_params;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny  all;
    }


(cat<<-EOF
<?php
phpinfo();
?>
EOF
)>/var/www/test/index.php

Я установил phpmyadmin без указания базы данных.
На хосте у меня установлена база данных mariadb в docker 
appuser@nginx-learn:~$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED      STATUS      PORTS                                       NAMES
067f2a542c7d   mariadb:10.7   "docker-entrypoint.s…"   5 days ago   Up 4 days   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp   wp_database

Какие настройки и где мне нужно сделать чтобы подключить phpmyadmin к этой базе?
