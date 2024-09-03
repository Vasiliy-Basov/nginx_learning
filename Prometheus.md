# Prometheus

## Установка

Лучше ставить в docker режиме
<https://prometheus.io/docs/prometheus/latest/installation/>

Ссылка на конфиг
<https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus.yml>

### Из документации

```bash
# Create persistent volume for your data
docker volume create prometheus-data
# Start Prometheus container
docker run \
    -p 9090:9090 \
    -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
    -v prometheus-data:/prometheus \
    prom/prometheus
```

Используем этот метод если хотим чтобы docker сам создал volume, путь к базе данным тогда можно посмотреть командой 

```bash
docker volume inspect prometheus-data
```

### Создаем каталог для базы сами и запускаем от конкретного пользователя

```bash
sudo mkdir -p /media/baggurd/ssd_samsung_465gb/prometheus/data
sudo chown -R baggurd:baggurd /media/baggurd/ssd_samsung_465gb/prometheus/data
sudo chmod 755 /media/baggurd/ssd_samsung_465gb/prometheus/data

docker run -d --name prometheus \
    -p 9090:9090 \
    -v /media/baggurd/ssd_samsung_465gb/prometheus/data:/prometheus \
    -v /media/baggurd/ssd_samsung_465gb/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
    --user $(id -u baggurd):$(id -g baggurd) \
    prom/prometheus
```

### Так же через docker-compose

```bash
cd /media/baggurd/ssd_samsung_465gb/prometheus
nano docker-compose.yml
```

```yaml
version: '3.8'  # Версия Docker Compose

services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"  # Проброс порта
    volumes:
      - /media/baggurd/ssd_samsung_465gb/prometheus/data:/prometheus  # Монтирование директории данных
      - /media/baggurd/ssd_samsung_465gb/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  # Монтирование файла конфигурации
    user: "${UID}:${GID}"  # Установка пользователя и группы для контейнера
    # Эти пути и команды выполняются внутри контейнера например:
    #command:
    #  - '--storage.tsdb.retention.size=10GB
    restart: always
```

Создаем файл с переменными рядом с docker-compose.yml

```bash
cd /media/baggurd/ssd_samsung_465gb/prometheus
touch .env
# Добавляем UID и GID текущего пользователя
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
```

```bash
# Запускаем
docker-compose up -d
```

```bash
# Посмотреть из под какого пользователя работает контейнер
docker inspect prometheus --format='{{.Config.User}}'
```

Делаем службу

```bash
sudo nano /etc/systemd/system/prometheus.service
```

```service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
PartOf=docker.service
After=docker.service

[Service]
User=baggurd
Group=baggurd
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/media/baggurd/ssd_samsung_465gb/prometheus
EnvironmentFile=/media/baggurd/ssd_samsung_465gb/prometheus/.env
ExecStart=/usr/local/bin/docker-compose up -d --remove-orphans
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service
sudo systemctl status prometheus.service
docker ps
docker inspect prometheus --format='{{.Config.User}}'
```

### Основные параметры запуска

--config.file="prometheus.yml" - какой конфигурационный файл использовать;
--web.listen-address="0.0.0.0:9090" - адрес, который будет слушать встроенный веб-сервер;
--web.enable-admin-api - включить или отключить административный API через веб-интерфейс;
--web.console.templates="consoles" - путь к директории с шаблонами html;
--web.console.libraries="console_libraries" - путь к директории с библиотеками для шаблонов;
--web.page-title - заголовок веб-страницы (title);
--web.cors.origin=".*" - настройки CORS для веб-интерфейса;
--storage.tsdb.path="data/" - путь для хранения time series database;
--storage.tsdb.retention.time - время хранения метрик по умолчанию 15 дней, все, что старше, будет удаляться;
--storage.tsdb.retention.size - размер TSDB, после которого Prometheus начнет удалять самые старые данные;
--query.max-concurrency - максимальное одновременное число запросов к Prometheus через PromQL;
--query.timeout=2m - максимальное время выполнения одного запроса;
--enable-feature - флаг для включения различных функций, описанных здесь;
--log.level - уровень логирования.

## Install node_exporter

Инсталлируем с помощью ansible
../Projects/nginx_learning/ansible

```bash
ansible-playbook node_exporter.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```

В gcp нужно открыть порт 9100 делаем это через terraform
../Projects/nginx_learning/terraform

или не GCP и с помощью ssh

inventory.ini
```
[local]
localhost ansible_connection=local
```
```bash
ansible-playbook node_exporter.yaml --ask-become-pass
```

Проверка что все работает:
http://nginx.basov.world:9100/metrics
http://localhost:9100/metrics



## Ключи запуска Node Exporter
Эти переменные вносим здесь
/home/baggurd/Dropbox/Projects/nginx_learning/ansible/roles/node_exporter/vars/main.yaml
/home/baggurd/Dropbox/Projects/nginx_learning/ansible/roles/node_exporter/templates/node_exporter

./node_exporter --help - посмотреть параметры

Далее приведен список наиболее востребованных ключей Node Exporter
```
--log.level
Default: info
Данный ключ устанавливает уровень логирования. Возможные уровни логирования:
debug, info, warn, error.
```
```
--log.format
Defult: logfmt
Данный ключ устанавливает формат логов. Доступные форматы: logfmt и json.
```
```
--web.listen-address
Default: ":9100"
Данный ключ устанавливает адрес и порт, по которому будет доступен Node Exporter.
```
```
--web.telemetry-path
Default: "/metrics"
Данный ключ устанавливает адрес, по которому доступны результаты экспозиции.
```
```
--web.disable-exporter-metrics
Default: -
Данный ключ устанавливает список метрик, которые будут исключены из экспозиции.
Например, для исключения всех метрик, имя которых начинается с go_, значение ключа
будет: go_*. Допускается использовать перечисление нескольких метрик, с запятой в
качестве разделителя.
Полный список ключей можно просмотреть с помощью команды help.
node_exporter --help
```

## blackbox exporter
Инсталлируем с помощью ansible
../Projects/nginx_learning/ansible

```bash
ansible-playbook blackbox_exporter.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```

### ICMP протокол
добавили в blackbox.yml
```yaml
  icmp_slurm:
    prober: icmp
    timeout: 2s
    icmp:
      preferred_ip_protocol: "ip4"
```
prober: задает, какой протокол будет использован для проверки. Возможные значения:
icmp | dns | tcp | http.
Далее идут настройки, специфичные для каждого протокола.

Если мы хотим проверить доступность сервера prometheus.io с сервера где стоит blackbox exporter можем это сделать с помощью icmp_slurm
```bash
curl -is "http://localhost:9115/probe?module=icmp_slurm&target=prometheus.io" | grep probe_success
```
Результат должен быть таким:
```
# HELP probe_success Displays whether or not the probe was a success
# TYPE probe_success gauge
probe_success 1
```
или извне
```
http://nginx.basov.world:9115/probe?module=icmp_slurm&target=prometheus.io
```

### Полный список параметров для проверки по ICMP протоколу:
```
timeout
Default: scrape_timeout
Время, после которого проверка будет считаться неудачной. ​NB!​ Если значение не
задано, используется scrape_timeout, который передал Prometheus.
```
```
preferred_ip_protocolDefault: ip6
Какой протокол используется для проверки. Допустимые значения: ip4| ip6.
```
```
source_ip_address
Default: -
Если на сервере несколько IP адресов, можно указать, с какого ip будет проводиться
проверка.
```
```
dont_fragment
Default: false
Разрешен ли бит фрагментации пакетов. ​!NB ​Работает только с linux и IPv4.
```
```
payload_size
Default: -
Размер пакета, который отправляется при выполнении проверки.
```

## DNS протокол
В данной конфигурации будет проверяться, может ли DNS сервер разрешить имя prometheus.io
```yaml
  dns_slurm:
    prober: dns
    timeout: 2s
    dns:
      query_name: prometheus.io
      preferred_ip_protocol: ip4
```

В запросе, в качестве параметра module, передаётся имя проверки, а в качестве
параметра target – на какой DNS сервер будет отправлен запрос. С помощью grep
фильтруем результат, чтобы получить только результат проверки.
```bash
curl -is "http://localhost:9115/probe?module=dns_slurm&target=8.8.8.8" | grep probe_success
```

### Полный список параметров для проверки по dns протоколу:
```
timeoutDefault: scrape_timeout
Время, после которого проверка будет считаться неудачной. ​NB!​ Если значение не
задано, используется scrape_timeout, который передал Prometheus.
```
```
preferred_ip_protocol
Default: ip6
Какой протокол используется для проверки. Допустимые значения: ip4| ip6.
```
```
source_ip_address
Default: -
Если на сервере несколько IP адресов, можно указать, с какого ip будет проводиться
проверка.
```
```
transport_protocol
Default: udp
Протокол, по которому будет производиться проверка. Возможные значения: udp, tcp.
```
```
query_name​:
Default: -
Запрос, который будет отправлен на DNS сервер.
```
```
query_type
Default: "ANY"
Тип записи, который будет запрашиваться. По умолчанию, запрашиваются все типы
записей.
```

## TCP протокол
```yaml
  tcp_slurm:
    prober: tcp
    timeout: 2s
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
      preferred_ip_protocol: "ip4"
```
В данной конфигурации будет проверяться, присутствует ли в ответе строка: SSH-2.0-
проверка
```bash
curl -is "http://localhost:9115/probe?module=tcp_slurm&target=127.0.0.1:22" | grep probe_success
```

### Полный список параметров для проверки по TCP протоколу:
```
timeout
Default: scrape_timeout
Время, после которого проверка будет считаться неудачной. ​NB!​ Если значение не
задано, используется scrape_timeout, который передал Prometheus.
```
```
preferred_ip_protocol
Default: ip6
Какой протокол используется для проверки. Допустимые значения: ip4| ip6.
```
```
query_response
* expect - проверка на наличие строки в ответе.
* send - позволяет задать, какой запрос будет отправлен на сервер.
* starttls - задает, будет ли использоваться tls при подключении, по умолчанию – false.
```
```
source_ip_address
Default: -
Если на сервере несколько IP адресов, можно указать, с какого ip будет проводиться
проверка.
```
```
tls
Default: false
Использовать ли tls после подключения.
```
```
tls_config
Настройки для tls. Возможны следующие ​настройки для tls​:
* insecure_skip_verify ​–​ ​проверять ли валидность сертификата. Значение по умолчанию – false.
* ca_file​ – путь к файлу с корневыми сертификатами.
* cert_file​ – путь к файлу с клиентским сертификатом.
* key_file ​– путь к файлу с клиентским ключом.
* server_name​ – строка для проверки имени сервера.
```

## HTTP протокол

В данной конфигурации для проверки используется протокол ip v4, проверяется версия
HTTP, код ответа, метод GET. Также проверка закончится с ошибкой, если не
используется https или если в ответе отсутствует слово: Prometheus.

```yaml
  http_slurm:
    prober: http
    timeout: 2s
    http:
      preferred_ip_protocol: "ip4"
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: [200]
      fail_if_not_ssl: true
      method: GET
      fail_if_body_not_matches_regexp:
        - "Prometheus"
```
```bash
curl -is "http://localhost:9115/probe?module=http_slurm&target=http://prometheus.io" | grep probe_success
```
## Debug
```bash
curl -is "http://localhost:9115/probe?module=http_slurm&target=http://prometheus.io&debug=true"
```
## Полный список параметров для проверки по HTTP протоколу:
```
timeout
Default: scrape_timeout
Время, после которого проверка будет считаться неудачной. ​NB!​ Если значение не
задано, используется scrape_timeout, который передал Prometheus.
```
```
preferred_ip_protocol
Default: ip6
Какой протокол используется для проверки. Допустимые значения: ip4| ip6.
```
```
source_ip_address
Default: -
Если на сервере несколько IP адресов, можно указать, с какого ip будет проводиться
проверка.
```
```
valid_status_codes
default: 200
Проверка считается неудачной, если код не соответствует заданному.
```
```
valid_http_versions
Проверка считается неудачной, если версия HTTP не соответствует строке.
```
```
method
Default: GET
Тип запроса. Возможные значения: GET | POST.
```
```
headers
Список заголовков, которые передаются во время проверки.
```
```
no_follow_redirects
Default: false
Следовать ли редиректам при проверке.
```
```
fail_if_ssl
Deafult: false
Проверка считается неуспешной, если соединение установлено по https.
```
```
fail_if_body_matches_regexp
Проверка считается неуспешной, если в body присутствует строка удовлетворяющая
регулярному выражению.
```
```
fail_if_body_not_matches_regexp
Проверка считается неуспешной, если в body отсутствует строка удовлетворяющая
регулярному выражению.
```
```
fail_if_header_matches
Проверка считается неуспешной, если в ответе присутствует заголовок, значение
которого удовлетворяет регулярному выражению.
* header – имя заголовка, который проверяется.
* regexp – регулярное выражение, которое проверяется в значении заголовка.
* allow_missing – разрешить отсутствие заголовка. По умолчанию: false.
```
```
fail_if_header_not_matches
Проверка считается неуспешной, если в ответе отсутствует заголовок, значение которого
удовлетворяет регулярному выражению.
* header – имя заголовка, который проверяется.
* regexp – регулярное выражение, которое проверяется в значении заголовка.
* allow_missing – разрешить отсутствие заголовка. По умолчанию: false.
```
```
basic_auth
* username – имя пользователя, которое используется для авторизации на проверяемом сайте.
* password – пароль, который используется для авторизации на проверяемом сайте.
```
```
bearer_token
Токен для bearer авторизации.
```
```
bearer_token_file
Файл, который содержит токен для bearer авторизации.
```
```
proxy_url
Адрес proxy сервера, если проверку необходимо выполнить через proxy сервер.
```
```
body
Body, которое передается вместе с запросом.
```
```
tls_config
* insecure_skip_verify ​–​ ​проверять ли валидность сертификата. Значение по умолчанию: false
* ca_file​ – путь к файлу с корневыми сертификатами.
* cert_file​ – путь к файлу с клиентским сертификатом.
* key_file ​– путь к файлу с клиентским ключом.
* server_name​ – строка для проверки имени сервера.
```

## Настройка со стороны Prometheus
```yaml
scrape_configs:
  - job_name: blackbox
    metrics_path: /probe
    # Какой модуль используем для проверки
    params:
      module: [http_slurm]
    static_configs:
      # адрес проверяемого ресурса.
      - targets:
        - "http://www.prometheus.io"
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115
```

## Default port allocations
Занятые порты которые лучше не использовать если пишем свой экспортер
https://github.com/prometheus/prometheus/wiki/Default-port-allocations


## Ключи запуска Prometheus

Далее приведен список наиболее востребованных ключей Prometheus:
```
--config.file
Default: "prometheus.yml"
Путь к конфигурационному файлу Prometheus. Если путь не полный, то поиск
производится по каталогу, из которого запущен Prometheus.
```
```
--web.listen-address
Default: "0.0.0.0:9090"
Адрес и порт, по которому доступны UI и метрики Prometheus.
```
```
--web.read-timeout
Default: 5m
Максимальное время ожидания ответа от сервера и закрытия idle подключений.
```
```
--storage.tsdb.path
Default: "data/"
Путь к каталогу для сохранения метрик.
```
```
--storage.tsdb.retention.time
Default: -
Как долго хранить данные метрик. Время хранения метрик, по умолчанию: 15 дней.
```
```
--storage.tsdb.retention.size
Default: 0B
[​Экспериментальная​] Максимальный размер, отведенный под хранение метрик.
Допускаются следующие единицы: KB, MB, GB, TB, PB. Первыми удаляются наиболее
старые данные.
```
```
--storage.remote.flush-deadlineDefault: 1m
Как долго ожидать окончания процесса сохранения данных при restart и reload.
```
```
--rules.alert.for-outage-tolerance
Default: 1h
Максимальное задержки для "for".
```
```
--rules.alert.for-grace-period
Default: 10m
Минимальное время восстановления состояния.
```
```
--rules.alert.resend-delay
Default: 1m
Минимальное время ожидания до отправки сообщения в Alertmanager.
```
```
--alertmanager.notification-queue-capacity
Default: 10000
Максимальное число сообщений, ожидающих отправки в Alertmanager.
```
```
--alertmanager.timeout
Default: 10s
Timeout для отправки сообщений в Alertmanager.
```
```
--query.timeout
Default: 2m
Максимальное время для выполнения запроса, после этого запрос будет сброшен.
```
```
--query.max-concurrency
Default: 20
Максимальное число параллельно выполняющихся запросов.
```
```
--log.levelDefault: info
Данный ключ устанавливает уровень логирования. Возможные уровни логирования:
debug, info, warn, error.
```
```
--log.format
Default: logfmt
Данный ключ устанавливает формат логов. Доступные форматы: logfmt и json.
```
```
Полный список ключей можно просмотреть с помощью команды help:
prometheus --help
```

## PushGateway 
Сервис с которого prometheus собирает метрики которые могут сюда посылать по технологии push сервисы которые например не существуют долго. Например отработала какая-то задача и завершилась и отправила метрики на pushgateway а оттуда уже эти метрики забирает prometheus.

Pushgateway не очищает данные которые к нему приходят
### Ключи запуска PushGateway
Далее приведен список наиболее востребованных ключей Pushgateway:
```
--log.level
Default: info
Данный ключ устанавливает уровень логирования. Возможные уровни логирования:
debug, info, warn, error.
```
```
--log.format
Default: logfmt
Данный ключ устанавливает формат логов. Доступные форматы: logfmt и json.
```
```
--web.listen-address
Default: ":9091"
Данный ключ устанавливает адрес и порт, по которому будет доступен PushGateway.
```
```
--web.telemetry-path
Default: "/metrics"
```
```
--web.enable-admin-api
Default: -
Разрешить endpoints для администрирования. Это может потребоваться для очистки
данных pushgateway.
```
```
--persistence.file
Default: -
Файл для сохранения метрик. По умолчанию, значения метрик сохраняются только в
памяти.
```
```
--persistence.interval
Default: 5mМинимальное время, через которое данные будут сохранены в постоянный файл.
Полный список ключей можно просмотреть с помощью команды help:
pushgateway --help
```

### Структура URL

Имя задачи и labels передаются как часть URL. Все запросы начинаются с /metrics
```
/metrics/job/<JOB_NAME>{/<LABEL_NAME>/<LABEL_VALUE>}
```
```
<JOB_NAME> - используется как значение label job и является обязательным.
Далее идут пары <LABEL_NAME>/<LABEL_VALUE>, где
<LABEL_NAME> это имя label
<LABEL_VALUE> значение этого label
Их количество не ограничено.
```

Например, метрика:
```
slurm_pushgateway_test{job="test_job",instance="localhost", edu="slurm"}
```
будет преобразована в:
```
/metrics/job/test_job/instance/localhost/edu/slurm/
```
```
!!NB! ​Если label содержит "/", пробел или русские символы, то его необходимо
закодировать в base64. А при запросе указать @base64. Данная ключевое слово
помогает PushGateway понять, что контент закодирован.
```

Например, для передачи в качестве значения для label path, /var/tmp запрос будет выглядеть так
```
/metrics/job/test_job/path@base64/L3Zhci90bXA
```

### Метод PUT
Метод PUT в Pushgateway используется для отправки метрик на сервер Pushgateway

- PUT запрос замещает все метрики для группы. Код ответа может быть 200 – в случае успешного обновления, и 400 – в случае ошибки.
- Если запрос выполняется с пустым body, то это приводит к удалению всех метрик для группы. При этом push_times_seconds не обновляется.
- push_times_seconds – метка времени последнего удачного POST или PUT запроса.
- push_failure_time_seconds – метка времени последнего неудачного POST или PUT
запроса.

Пример использования метода PUT для отправки метрик на Pushgateway:
```
PUT /metrics/job/<job_name>/instance/<instance_label>
Content-Type: text/plain

# TYPE <metric_name> <metric_type>
<metric_name>{<label_name>=<label_value>} <metric_value>
```

Пример запроса с использованием cURL (отправляем метрику):
```
curl -XPUT -H "Content-Type: text/plain" --data-binary \
'# TYPE my_metric counter
my_metric{label1="value1", label2="value2"} 42' \
http://pushgateway.example.com/metrics/job/my_job/instance/my_instance
```
Обратите внимание, что в приведенном примере my_metric - это имя вашей метрики, label1 и label2 - это метки (label) для группировки метрик, 42 - значение метрики.

### Метод POST
Метод POST в Pushgateway используется для отправки группы метрик на сервер Pushgateway.

POST запрос работает аналогично PUT, но обновляет значение только для метрик,
которые присутствуют в запросе.
Если запрос выполняется с пустым body, то push_times_seconds обновляется, а
изменение ранее переданных метрик не производится.

```
POST /metrics/job/<job_name>/instance/<instance_label>
Content-Type: text/plain

# TYPE <metric_name_1> <metric_type>
<metric_name_1>{<label_name_1>=<label_value_1>} <metric_value_1>

# TYPE <metric_name_2> <metric_type>
<metric_name_2>{<label_name_2>=<label_value_2>} <metric_value_2>

...
```
Пример запроса с использованием cURL:
```
curl -XPOST -H "Content-Type: text/plain" --data-binary \
'# TYPE my_metric_1 counter
my_metric_1{label1="value1", label2="value2"} 42
# TYPE my_metric_2 gauge
my_metric_2{label1="value1", label2="value2"} 3.14' \
http://pushgateway.example.com/metrics/job/my_job/instance/my_instance
```

В этом примере мы отправляем две метрики: my_metric_1 с типом счетчика (counter) и my_metric_2 с типом метрики gauge. У каждой метрики есть метки (labels) label1 и label2 со значениями "value1" и "value2" соответственно.


Передаем метрики на pushgateway:
```
cat <<EOF | curl --data-binary @- http://127.0.0.1:9091/metrics/job/slurm_io_test_job/instance/nginx.basov.world
# TYPE slurm_io_edu_counter counter
slurm_io_edu_counter{type="counter"} 42
# TYPE slurm_io_gauge gauge
slurm_io_gauge 2398.283
EOF
```
Это метод POST. В команде curl, указанная операция --data-binary указывает, что данные должны быть отправлены в виде двоичных данных (без изменений), и именно этот метод используется по умолчанию при выполнении команды curl без указания явного метода

Метод POST используется для создания новых ресурсов или отправки данных на сервер. В данном случае, данные метрик отправляются на URL-адрес http://127.0.0.1:9091/metrics/job/slurm_io_test_job/instance/nginx.basov.world с помощью метода POST.

Когда используется метод POST, данные метрик передаются в теле запроса HTTP, что позволяет отправлять несколько метрик одновременно или отправлять более сложные данные, чем просто одна метрика.

Проверка что метрика отправилась
```bash
curl -L http://localhost:9091/metrics/ 
```

Ответ должен быть примерно таким:
```
push_failure_time_seconds{instance="monitoring.s00000.slurm.io",job="slurm_io_test_job"} 0
push_time_seconds{instance="monitoring.s00000.slurm.io",job="slurm_io_test_job"}
1.5736548226639028e+09
# TYPE slurm_io_edu_counter counter
slurm_io_edu_counter{instance="monitoring.s00000.slurm.io",job="slurm_io_test_job",type="co
unter"} 42
# TYPE slurm_io_gauge gauge
slurm_io_gauge{instance="monitoring.s00000.slurm.io",job="slurm_io_test_job"} 2398.283
```
```
push_failure_time_seconds равный 0. Это говорит о том, что еще не было неудачных отправок данных.
```
```
push_time_seconds, значение которой говорит о времени последней удачной отправки данных.
```
Также группировка произведена только по labels, которые передавались в URL. label type для slurm_io_edu_counter не учитывается.

В запросе был указан URL следующего вида: http://127.0.0.1:9091/metrics/job/slurm_io_test_job/instance/nginx.basov.world. Здесь slurm_io_test_job и nginx.basov.world являются метками (labels), по которым будет производиться группировка метрик.

Однако, фраза "label type для slurm_io_edu_counter не учитывается" указывает на то, что метка type для метрики slurm_io_edu_counter не будет использоваться для группировки метрик в Pushgateway. Это означает, что метрики с разными значениями type будут считаться как одна группа метрик, а не различные группы на основе значения этой метки.

Например, если бы вы отправили следующие метрики:
```
plaintext
Copy code
# TYPE slurm_io_edu_counter counter
slurm_io_edu_counter{type="counter", label1="value1"} 42
slurm_io_edu_counter{type="gauge", label1="value2"} 10
```
То обе метрики будут группироваться в одну группу slurm_io_edu_counter, игнорируя различие в значениях метки type. Это происходит потому, что метка type не была указана в URL-адресе запроса и, следовательно, не учитывается для группировки.

### UI PushGateway
http://nginx.basov.world:9091/
UI доступен по порту 9091. Интерфейс у него очень простой. В нем можно посмотреть
список групп, значение для метрик для каждой группы. Время последней удачной и
неудачной отправки данных. Можно также удалить группу.

### Метод DELETE
DELETE запрос используется для удаления метрик из PushGateway. Удаляется вся
группа метрик. Тело запроса всегда должно быть пустым.
При успешном выполнении код ответа всегда будет 202.

## Настройка Prometheus PushGateway
Настройка забора метрик (Scraping) c PushGateway


Как выполнить только определенный task в Ansible:
Выставляем tag на task и запускаем
```bash
ansible-playbook prometheus.yaml --private-key /home/baggurd/.ssh/appuser_ed25519 --tags "prometheus_config"
```
```prometheus.yml
  # Сбор метрик с pushgateway      
  - job_name: pushgateway
    honor_labels: true
    static_configs:
    - targets:
      - nginx.basov.world:9091
```

Заходим на prometheus http://nginx.basov.world:9090
Проверяем что метрики собрались:

```
slurm_io_edu_counter[1m]
```

# PromQL
В Prometheus есть 4 типа данных
* Counter - Может быть 0 или больше (не может принимать отрицательные значения)
* Gauge - может как уменьшаться так и увеличиваться (Например подходит для измерения свободной памяти на сервере)
* Histogram - Чаще используется для вычисления длительности запроса и размера ответа. Предоставляет информацию о количестве значений, попавших в определенные интервалы (бакеты), а также об общей сумме значений.
Histogramы в Prometheus обычно используются для измерения времени выполнения операций, количества запросов или других величин, которые могут быть разбиты на интервалы.

Для вычисления выражений с гистограммами в PROMQL доступны следующие функции:

    histogram_quantile: Вычисляет квантиль (процентиль) для гистограммы. Принимает два аргумента: значение квантиля и гистограмму.

    histogram_bucket: Возвращает количество наблюдений, попавших в указанный бакет гистограммы. Принимает два аргумента: значение бакета и гистограмму.

    histogram_sum: Возвращает общую сумму значений для гистограммы.

    histogram_count: Возвращает общее количество наблюдений (событий), попавших в гистограмму.

Пример использования выражений с гистограммами в PROMQL:
```
# Получить квантиль 90% для гистограммы с именем my_histogram
histogram_quantile(0.9, my_histogram)

# Получить количество наблюдений, попавших в бакет со значением 5.0 для гистограммы my_histogram
histogram_bucket(5.0, my_histogram)

# Получить общую сумму значений для гистограммы my_histogram
histogram_sum(my_histogram)

# Получить общее количество наблюдений (событий) для гистограммы my_histogram
histogram_count(my_histogram)
```
Гистограммы в PROMQL предоставляют полезную информацию о распределении данных, что позволяет более детально анализировать и мониторить различные метрики в системе.

- summary - расширенная Histogram
Summary в Prometheus подобен гистограмме, но предоставляет более легковесный способ оценки квантилей распределения. Он рассчитывает квантили "на лету" постепенно, основываясь на зарегистрированных образцах, и не требует хранения всех значений метрик, как в случае с гистограммой.

Для вычисления выражений с сводкой в PROMQL доступны следующие функции:

    quantile: Вычисляет квантиль (процентиль) для сводки. Принимает два аргумента: значение квантиля и сводку.

    avg: Возвращает среднее значение для сводки.

    sum: Возвращает общую сумму значений для сводки.

    count: Возвращает общее количество образцов (событий) для сводки.

Пример использования выражений с сводкой в PROMQL:
```
# Получить квантиль 90% для сводки с именем my_summary
quantile(0.9, my_summary)

# Получить среднее значение для сводки my_summary
avg(my_summary)

# Получить общую сумму значений для сводки my_summary
sum(my_summary)

# Получить общее количество образцов (событий) для сводки my_summary
count(my_summary)
```
Отличие между гистограммой и сводкой заключается в том, что гистограмма разбивает данные на бакеты с фиксированными интервалами и предоставляет информацию о количестве значений в каждом бакете, в то время как сводка основывается на квантилях и общем количестве образцов. Гистограмма более подходит для анализа распределения данных с детализацией по интервалам, тогда как сводка хорошо работает для получения квантилей и общих статистических показателей. Выбор между использованием гистограммы или сводки зависит от требуемых целей мониторинга и анализа.

## Типы данных в PromQL
В запросах Prometheus есть 3 типа данных:
- Instant vector​ – вектор содержит в себе все значения метрики по запрашиваемой метке времени.
- Range vectors​ – возвращает все вектора за указанный период времени. Это позволяет увидеть изменение метрики во времени.
- Scalar​ ​–​ простое числовое значение с плавающей точкой.

### Математические операторы
```
Сложение (+): Складывает значения метрик или скалярные значения. Например: metric1 + metric2 или scalar1 + scalar2.

Вычитание (-): Вычитает значения метрик или скалярные значения. Например: metric1 - metric2 или scalar1 - scalar2.

Умножение (*): Умножает значения метрик или скалярные значения. Например: metric1 * metric2 или scalar1 * scalar2.

Деление (/): Делит значения метрик или скалярные значения. Например: metric1 / metric2 или scalar1 / scalar2.

Возведение в степень (^): Возводит значения метрик или скалярные значения в указанную степень. Например: metric1 ^ metric2 или scalar1 ^ scalar2.

Остаток от деления (%): Возвращает остаток от деления значений метрик или скалярных значений. Например: metric1 % metric2 или scalar1 % scalar2.

Негация (-): Изменяет знак значения метрики или скалярного значения на противоположный. Например: -metric1 или -scalar1.

Скобки (): Используются для управления порядком выполнения операций. Выражения в скобках будут вычисляться в первую очередь.
```

### Операторы сравнения:
```
== – равно
!= – не равно
> – больше
< – меньше
>= – больше или равно
<= – меньше или равно
```

Сравнение возможно только над scalar и instant vector. Оператор применяется к каждому значению в исходном векторе, и все элементы данных, для которых не выполняется  условие сравнения, исключаются из результирующего вектора.
Если указан модификатор bool, то в результирующем векторе данные, которые
удовлетворяют условию сравнения, будут иметь значение 1, а не удовлетворяющие 0.

NB! ​Сравнение двух scalar возможно только с модификатором bool.

### Логические операторы:
```
and – логическое И
or – логическое ИЛИ
unless – дополнение
```
Логические операторы возможны только между instant vector.

Пример использования оператора and:
Предположим, у нас есть метрика http_requests_total, которая показывает общее количество HTTP-запросов, и мы хотим найти метрики, где количество запросов больше 1000 и код ответа равен 200.

```
http_requests_total{status_code="200"} > 1000 and http_requests_total > 1000
```
Этот запрос вернет метрики http_requests_total, где общее количество запросов больше 1000 и код ответа равен 200.

Пример использования оператора or:
Предположим, у нас есть метрика cpu_usage, которая показывает процент использования CPU, и мы хотим найти метрики, где процент использования CPU больше 90% или процент использования памяти больше 80%.

```
cpu_usage > 90 or memory_usage > 80
```
Этот запрос вернет метрики, где либо процент использования CPU больше 90%, либо процент использования памяти больше 80%.

Пример использования оператора unless:
Предположим, у нас есть метрика http_requests_total, которая показывает общее количество HTTP-запросов, и мы хотим найти метрики, где количество запросов не превышает 1000.
```
unless http_requests_total > 1000
```
Этот запрос вернет метрики http_requests_total, где общее количество запросов не превышает 1000.


## Сумарное потребление cpu по двум серверам

```
node_cpu_seconds_total{instance="nginx.basov.world:9100",job="static_config"}+on(cpu, mode) node_cpu_seconds_total{instance="vasiliy.basov.world:9100",job="static_config"}
```

Существует 2 модификатора для сравнения:
- on – задает, какие labels необходимо учитывать при сопоставлении.
- ignoring – задает, какие labels должны быть исключены в процессе
сопоставления.

## Операторы агрегации:
- sum – сумма
- min – минимальное значение
- max – максимальное значение
- avg – среднее значение
- stddev – стандартное отклонение
- stdvar – стандартная дисперсия
- count – количество элементов в векторе
- count_values – количество элементов с одинаковым значением.

Данные операторы могут использоваться с модификаторами ​by​ и ​without​. C помощью модификатора by задается список labels, которые будут учитываться, а модификатор without задает список labels, которые учитываться не будут. Указание данного модификатора допускается как до, так и после запроса.
```
operator ([parameter,] <vector expression>) [without|by (<label list>)]
```

Например, чтобы получить суммарное потребление cpu по всем инстансам в user mode,
выполните следующий запрос:
```
sum(node_cpu_seconds_total{mode="user"}) by (cpu)
```

Чтобы получить суммарное потребление процессора в user mode по всем ядрам,
выполните запрос:

```
sum without (cpu) (node_cpu_seconds_total{mode="user"})
```

## Приоритет бинарных операторов
Бинарные операторы имеют следующий приоритет:
1. ^
2. * , / , %
3. + , -
4. == != , <= , < , >= , >
5. and , unless
6. or

## Математические функции
```
abs
Функция возвращает абсолютные значения, то есть любые отрицательные значения
заменяются положительными. abs(vector(-10)) вернет: 10
```
```
ln, log2, and log10
Набор данных функций принимают мгновенный вектор и возвращают логарифм значений,
используя разные основания.
```
```
exp
Функция возвращает экспоненту для моментального вектора. Эта функция является
обратной для ln.
```
```
sqrt
Функция возвращает результат возведения в квадратный корень. Она эквивалентна
математическому выражению ^ 0.5.
```
```
ceil​ ​and floor
Функция округления значений вектора.
ceil – округляет в большую сторону: ceil(vector(1.1)) вернет 2.
floor – округляет в меньшую сторону: floor(vector(1.1)) вернет 1.
```
```
round
Функция возвращает результат округления. Округление производится до ближайшего
целого числа.
round (vector(1.1)) вернет: 1, round (vector(1.6)) вернет: 2.
Если значение находится ровно посередине между двумя целыми числами, округление
производится в большую сторону.
round (vector(1.5)) вернет: 2.Для функции round может быть задан дополнительный аргумент. В этом случае функция
вернет ближайшее целое число кратное, заданному аргументу. round(vector(17), 5)
вернет: 15
```
```
clamp_max and clamp_min
Функция clamp_max – заменяет все значения выше заданного на максимальное.
clamp_max(vector(9), 5) вернет: 5.
Функция clamp_min – заменяет все значения меньше заданного на минимальное.
clamp_min(vector(3), 5) вернет: 5.
```

## Функции времени и даты
```
time
Функция возвращает текущее время в Unix time формате.
```
```
minute, hour, day_of_week, day_of_month, days_in_month, month, and
year
Данные функции возвращают:
minute - минуты
hour - часы
day_of_week - день недели
day_of_month - день месяца
days_in_month - количество дней в месяце
month - месяц
year - год
В качестве аргументов эти функции могут принимать вектор, значение которого – дата.
Например, year(process_start_time_seconds) вернет год, в котором был запущен процесс.
```
```
timestamp
Это функция, в отличие от остальных функций времени, смотрит не на значение вектора,
а на его временную метку и возвращает ее значение.
```

## Метки
```
label_replace
Функция позволяет добавить новую метку на основании уже имеющихся. Это удобно,
когда вы агрегируете данные из разных источников, где метки имеют одинаковый смысл,
а их названия различаются. Например, запрос label_replace(up, "replace", "${1}", "job",
"(.*)") вернет: up{instance="localhost:9090",job="prometheus",replace="prometheus"}
```
```
label_join
Позволяет объединять значения нескольких меток в одну. Например, запрос label_join(up,
"join", "-", "job", "instance") вернет:
up{instance="localhost:9090",job="prometheus",join="prometheus-localhost:9090"}
```
Важно!​ label_join и label_replace не удаляют имена метрик.

## Пропущенные серии
```
absent
Функция возвращает пустой вектор, если переданный ей вектор содержит значения. В
противном случае она возвращает 1.
```

## Сортировки
```
sort
Функция позволяет отсортировать значения в возвращаемом векторе. Сортировка
производится по возрастанию.
```
```
sort_desc
Функция позволяет отсортировать значения в возвращаемом векторе. Сортировка
производится по убыванию
```
## Агрегация во времени

<aggregation>_over_time()
Следующие функции позволяют агрегировать каждую серию заданного диапазона
вектора во времени и возвращать мгновенный вектор с результатами агрегации для
каждой серии:
```
avg_over_time
Функция возвращает среднее значение всех точек в указанном интервале.
```
```
min_over_time
Функция возвращает минимальное значение всех точек в указанном интервале.
```
```
max_over_time
Функция возвращает максимальное значение всех точек в указанном интервале.
```
```
sum_over_time
Функция возвращает сумму всех значений в указанном интервале.
```
```
count_over_time
Функция возвращает количество всех значений в указанном интервале.
```
```
quantile_over_time
Функция возвращает φ-квантиль (0 ≤ φ ≤ 1) значений в указанном интервале.
```
```
stddev_over_time
Функция возвращает стандартное отклонение совокупности значений в указанном
интервале.
```
```
stdvar_over_time
Функция возвращает стандартную дисперсию совокупности значений в указанном
интервале.
```


## Функции для сounter
```
topk и bottomk
Функция вычисляет среднюю скорость увеличения временного ряда в секунду. При
сбросе счетчика в 0, данные корректируются, чтобы это не влияло на конечный результат.
NB! ​topk и bottomk при использовании с by и without, в отличие от остальных операторов
агрегации, возвращают полный набор метрик, а by и without используется только для группировки значений.
```
```
increase
Функция вычисляет увеличение во временном ряду в диапазоне вектора. Формула для
расчета: rate(x_total [time]) * time
```
```
irate
Функция вычисляет мгновенную скорость увеличения временного ряда в векторе
диапазона. Он похож на rate, но для анализа использует последние две выборки вектора.
```
```
resets
Функция вычисляет число сбросов счетчика в предоставленном временном диапазоне в
качестве мгновенного вектора. Любое уменьшение значения между двумя
последовательными выборками интерпретируется как сброс счетчика.
```
## Функции для Histograms

```
histogram_quantile
Функция группирует значения по bucket, а затем вычисляет φ-квантиль (0 ≤ φ ≤ 1).
Функция rate() позволяет произвести расчет за период времени. Функция:
histogram_quantile(0.90,rate(prometheus_tsdb_compaction_duration_seconds_bucket[1d]))
рассчитывает 0,9 квантиль для prometheus_tsdb_compaction_duration_seconds_bucket за
предыдущий день.
Значения за пределами 0 ≤ φ ≤ 1 не имеют смысла и равняются бесконечности.
Предпочтительным способом расчета квантили является использование​ ​Summary, но
некоторые exporters предоставляют данные в виде Histogram. В этом случае
использование функции​ ​histogram_quantile является обоснованным.
```
## Функции для Gauges
```
changes
Функция позволяет подсчитать, сколько раз временной ряд изменил свое значение.
Данная функция удобна, например, для подсчета количества перезапусков процесса за период времени.
```
```
deriv
Функция позволяет узнать скорость изменения временного ряда в секунду за период
времени. Эта функция похожа на x - x offset 1h, но на результат данного запроса могут
повлиять локальные выбросы, а deriv для расчета значения использует функцию простой
линейной регрессии, что делает ее результат точнее и устойчивее к локальным
выбросам.
```
```
predict_linear
Функция возвращает предсказание о значении временного ряда через n секунд.
Предсказание вычисляется с помощью функции простой линейной регрессии.
```
```
delta
Функция похожа на increase и возвращает изменение временного ряда за период
времени, но без учета сбросов. Данная функция является чувствительной к локальным
выбросам и использовать ее стоит с осторожностью.
```
```
idelta
Функция возвращает разницу между последними 2-мя значениями во временном ряду.
```
```
holt_winters
Функция реализует двойное экспоненциальное сглаживание Holt-Winters. Это полезно для
очистки данных от локальных выбросов и оценки трендов изменения метрики. В качестве
входных параметров функция принимает временной ряд, коэффициент сглаживания и
коэффициент важности более старых данных по отношению к более новым.
```
## Record Rules
Можем сохранять результаты запроса в новый временной ряд
## Настройка Rules

Rules описываются в отдельном конфигурационном файле. Формат - yml. Prometheus
поддерживает загрузку правил из нескольких файлов. Rules загружаются только при
отсутствии ошибок во всех Rules. Для проверки на наличие синтаксических ошибок можно
использовать утилиту promtool.
```
promtool check rules /path/to/example.rules.yml
```
NB!​ На файлы с правилами не выставляется inotify, поэтому после любого изменения правил требуется, как минимум, выполнять reload – для того, чтобы Prometheus применил изменения.


Чтобы загрузить правила в Prometheus, список файлов с Rules необходимо взять в
основном конфигурационном файле Prometheus.
```
rule_files:
  - "rules_file1.yml"
  - "rules_file2.yml"
  - "rules/*.yml"
```

## Синтаксис rules файла
```yaml
groups:
  # это имя для группы правил
  - name: example
    # интервал, с которым будет производиться выполнение и сохранение правил в группе
    interval: 10s
    rules:
    # имя, по которому результат будет доступен при извлечении данных.
    - record: job:process_cpu_seconds:rate5m
      # выражение, которое используется для вычисления. Является обязательным.
      expr: sum without(instance)(rate(process_cpu_seconds_total[5m]))
      # список меток, которые будут добавлены к вектору. Не является обязательным.
      labels:
        slurm_edu: exmple_rules
```

## Именование Rules

Для Rules у Prometheus имеются рекомендации по именованию правил, что упрощает
интерпретацию значения правила.
1. Разделителем в имени правила является ":"
2. Общий вид имени должен быть таким:
level:metric:operations

- level ​–​ ​отражает уровень агрегации на основании labels. Он должен включать метку job и
другие значимые labels, которые имеют отношение к метрике.
- metric ​–​ ​это имя метрики. Допускается удаление _total, но в остальных случаях это
должно быть точное название исходной метрики. Для обозначения необходимо
использовать _per_.
- operations ​– представляет собой список функций и агрегаций, примененных к метрике.
Если применяется несколько одинаковых функций, например min, указывать необходимо
только одну.

Для лучшего понимания ниже приведено несколько примеров:

```
- record: instance_path:request_latency_seconds_count:rate5m
expr: rate(request_latency_seconds_count{job="myjob"}[5m])
```
```
- record: instance_path:request_latency_seconds_sum:rate5m
expr: rate(request_latency_seconds_sum{job="myjob"}[5m])
```
```
- record: job:request_failures_per_requests:ratio_rate5m
  expr: |2
    sum without (instance, path)(instance_path:request_failures:rate5m{job="myjob"}) / sum without (instance, path)(instance_path:requests:rate5m{job="myjob"})
```

## Настройка Alert Rules
Настраиваем ../nginx_learning/ansible/roles/prometheus/templates/rules_alert.yml
```
/etc/prometheus/rules_alert.yml
```
Добавляем данные о Rules в основной конфигурационый файл Prometheus.yml
```yaml
rule_files:
  - {{ prometheus_config_dir }}/rules.yml
  - {{ prometheus_config_dir }}/rules_alert.yml
```
Проверяем, что правила появились.
http://nginx.basov.world:9090/alerts

### Тестирование работы правил

Отключаем node_exporter, выполнив команду:
```bash
systemctl stop node_exporter.service
```
Возвращаемся на страницу: http://<адрес сервера monitoring>:9090/alerts. 
Одно из alert rule должно перейти в состояние PENDING
По истечению времени, указанного в for(5m), alert rule перейдет в состояние: FIRING

NB! ​Обратите внимание: Prom сам не обновляет страницы. Чтобы увидеть добавленные
данные, необходимо обновить страницу (нажать F5).
NB! ​Установленная галочка: "Show annotations" позволяет просмотреть Annotations labels
c уже подставленными в шаблон значениями.

## Настройка Alertmanager

ansible-playbook alertmanager.yaml --private-key /home/baggurd/.ssh/appuser_ed25519

Добавление в prometheus.yml
```yaml
# Alertmanager configuration
# Настройка для взаимодействия с Alert Manager.
alerting:
  # alert_relabel_configs:
  #   [ - <relabel_config> ... ]
  alertmanagers:
    - static_configs:
        - targets:
          - 'localhost:9093'
```

### Ключи запуска Alertmanager
Далее приведен список наиболее востребованных ключей Alertmanager:
```
--config.file
Default: alertmanager.yml
Имя конфигурационного файла.
```
```
--storage.path
Default: data/
Путь, куда сохраняются данные.
```
```
--data.retention
Default: 120h
Как долго хранить данные.
```
```
--web.listen-address
Default: ":9093"
Адрес и порт, по которому доступны UI и метрики Alertmanager.
```
```
--cluster.listen-address
Default: "0.0.0.0:9094"
Адрес для HA кластера. Пустое значение для отключения HA mode.
```
```
--cluster.advertise-address
Default: -
IP для анонса в кластере.
```
```
--cluster.peer
Defalut: -
Адреса peer в HA кластере.
```
```
--log.level
Default: info
Данный ключ устанавливает уровень логирования. Возможные уровни логирования:
debug, info, warn, error.
```
```
--log.format
Default: logfmt
Данный ключ устанавливает формат логов. Доступные форматы: logfmt и json.
```
```
Полный список ключей можно просмотреть с помощью команды help:
alertmanager --help
```

## Настройка Alertmanager

alertmanager.yml:

### Блок global
```
resolve_timeout
default: 5m Время, через которое алерт считается решенным, если в течение этого
времени он не был обновлен.
```
```
smtp_from​ default: – email адрес, который будет использован в качестве адреса
отправителя. В блоке global объявляются значения по умолчанию, переопределить
которые можно в блоке receiver.
```
```
smtp_smarthost
default:
Адрес SMTP сервера, который используется для отправки. Формат: ip:port . В блоке global объявляются значения по умолчанию, переопределить которые можно в блоке receiver.
```
```
smtp_require_tls
default: true
Задает, использовать ли tls при подключении к SMTP. ​NB!​ Обратите внимание, что
значение по умолчанию true и при использовании с локально установленным postfix без дополнительных настроек работать не будет.
Также в этой секции возможно настроить отправку уведомлений в: slack, hipchat,
pagerduty и другие мессенджеры. Но для настройки получателей рекомендуется
использовать webhook. Его настройка возможна только в разделе receivers.
```


### Блок route

В блоке route производится маршрутизация сообщений. В результате получается
древовидная структура.
```
receiver
Имя конфигурации, которая будет использована для отправки уведомлений.
```
```
group_by
Набор меток, по которым производится агрегация. Значение ['...'] отключает группировку.
```
```
сontinue
default: false
Если значение false, обработка уведомления прекращается при первом совпадении. Если значение true, обработка продолжается и выбирается последний route, удовлетворяющий условиям.
```
```
match
Список меток key: value, при точном совпадении с которыми выбирается этот маршрут.
```
```
match_re
Список меток key: regex, при совпадении с которыми выбирается этот маршрут.
```
```
group_wait
Default: 30s
Время задержки перед отправкой сообщений для группы. Позволяет дождаться
поступления большего числа алертов и произвести эффективную группировку.
```
```
group_interval
default: 5m
Время задержки для отправки новых уведомлений, по которым первоначальное
уведомление уже было отправлено.
```
```
repeat_interval
default: 4h
Время задержки для повторной отправки уведомления.
```

routes
Дополнительные маршруты. Не являются обязательными.
Пример:

```yaml
route:
  receiver: 'default-receiver'
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  group_by: [cluster, alertname]
  routes:
  - receiver: 'db-team'
    group_wait: 10s
    match_re:
      service: mysql|postgres
  - receiver: 'frontend-team'
  group_by: [product, environment]
  match:
    team: frontend
```
В этом примере все уведомления labels service со значениями mysql или postgres будут отправлены db-team. Уведомления, имеющие label team со значением frontend, будут отправлены frontend-team. Остальные уведомления будут отправлены получателю по-умолчанию.

### Блок receivers
Receiver – это именованная конфигурация одного или нескольких получателей
уведомлений. На данный момент имеется интеграция с несколькими мессенджерами:
slack, hipchat, pagerduty и др. Но для настройки получателей рекомендуется использовать webhook. В настройках указываются данные для отправки. Пример настройки email будет рассмотрен в следующем шаге.

### Блок inhibit_rules
Блок inhibit_rules позволяет отключить уведомления для алертов, у которых labels
соответствуют набору labels, указанных в target_match(_re), и при условии, что уже есть уведомление, у которого набор labels соответствуют набору labels, указанных в source_match(_re).
```
target_match
Список labels, при совпадении с которым сообщение будет отключено.
```
```
target_match_re
Список labels, при совпадении с которым сообщение будет отключено. Для проверки
используется регулярное выражение.
```
```
source_match
Набор меток, для которых уже должен существовать алерт, чтобы правило подавления
работало.
```
```
source_match_re
Набор меток, для которых уже должен существовать алерт, чтобы правило подавления
работало. Для проверки используется регулярное выражение.
```
```
equal
Набор label, которые должны совпадать в alert и inhibit alert, чтобы подавление работало.
```
### Блок templates
В данном блоке задается список путей для файлов с пользовательскими шаблонами
уведомлений. Допускается использование маски.
Пример:
```
templates:
- 'templates/*.tmpl'
```

NB!​ В реальной жизни routing будет намного сложнее, и для его визуализации можно
воспользоваться​ ​сайтом​. https://prometheus.io/webtools/alerting/routing-tree-editor/


### Настройка alertmanager практика

```yaml
# Чтобы эта настройка сработала нужно настроить пароль для приложений в настройках безопасности yandex
# также нужно поставть Разрешить доступ к почтовому ящику с помощью почтовых клиентов С сервера imap.yandex.ru по протоколу IMAP
global:
  smtp_smarthost: smtp.yandex.ru:465
  smtp_from: 'baggurdprom@yandex.ru'
  smtp_auth_username: 'baggurdprom@yandex.ru'
  smtp_auth_password: 'сложныйпароль'

route:
  # объединяем связанные уведомления в одну группу. Уведомления будут группироваться по значениям меток alertname (имя алерта) и service (сервис)
  group_by: ['alertname', 'service']
  # Время ожидания (в секундах) для формирования группы уведомлений
  group_wait: 30s
  # параметр определяет интервал (в минутах) между отправкой групп уведомлений
  group_interval: 5m
  # параметр определяет интервал (в часах) повторной отправки уведомлений, если состояние алерта не изменяется
  repeat_interval: 1h
  # Этот параметр указывает, какой получатель (receiver) будет использоваться для отправки уведомлений
  receiver: team-monitoring

  # Это правило указывает, что уведомления, которые имеют метку service со значением "prom", должны быть отправлены на получателя (receiver) с именем team-ops 
  routes:
  - receiver: 'team-ops'
    matchers:
    - service="prom"
  # Это правило указывает, что уведомления, которые имеют метку severity со значением "warnings", "error" или "critical", должны быть отправлены на получателя (receiver) с именем team-monitoring
  - receiver: 'team-monitoring'
    matchers:
    - severity=~"warnings|error|critical"

receivers:
- name: 'team-ops'
  email_configs:
  - to: 'baggurd@mail.ru'
    send_resolved: true
    require_tls: false
- name: 'team-monitoring'
  email_configs:
  - to: 'dramikon@mail.ru'
    send_resolved: true 

# Подавление уведомлений
inhibit_rules:
  # Это правило подавления будет применяться, когда уведомление имеет источник (source) с метками severity: 'critical' и alertname: PrometheusConfigurationReload, 
  # и при этом существует цель (target) с меткой severity: 'error'. В таком случае, уведомление, соответствующее этим условиям, не будет отправлено, и оно будет подавлено.
  - source_match:
      severity: 'critical'
      alertname: PrometheusConfigurationReload
    target_match:
      severity: 'error'

```
```bash
ansible-playbook alertmanager.yaml --private-key /home/baggurd/.ssh/appuser_ed25519 --tags "alertmanager_config"
```

## Настройка Grafana

```bash
ansible-playbook grafana.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```
Имя пользователя и пароль по умолчанию admin/admin
Добавляем Prometheus в качестве источника данных.
выбираем Add data source:
```
Name​ – имя data source, должно быть уникальным.
```
```
URL​ – адрес, где располагается prometheus. Так как grafana установлена на том же
сервере, что и Prom, указываем: http://localhost:9090
```
```
Access​ – способ подключения к Prometheus. Server – запрос из браузера отправляется в
grafana, grafana производит подключения к Prometheus. Browser – в этом случае запросы
в Prometheus отправляются напрямую из браузера. Метод Browser менее
предпочтителен, так как приводит к необходимости открывать прямой доступ к
Prometheus.
```
```
Auth ​– задаются учетные данные для подключения к Prom.
```
```
Scrape interval ​– рекомендуется выставить равным глобальному значению scrape,
установленному в Prometheus.
```
```
Query timeout​ – задает максимальное время выполнения запроса к Prometheus.
```
```
HTTP Method​ – метод для отправки запросов в Prom. Post запросы возможны, начиная с
версии: 2.1.0
```
Сохраняем изменения.

Настройка dashboard в Grafana
см слайды

Импорт дашбоардов
https://grafana.com/grafana/dashboards/11074

## Настройка Prometheus в режиме HA
Необходимо установить Prometheus на серверы ​server1 и server2
После установки на каждом из Prometheus серверов необходимо заменить конфигурационный файл

### Настройка HA Proxy
Для доступа из Grafana к Prom необходимо установить HAProxy, для повышения отказоустойчивости
Устанавливаем HAProxy:
```bash
ansible-playbook haproxy.yaml --private-key /home/baggurd/.ssh/appuser_ed25519 --limit prom
```
Настраиваем /etc/haproxy/haproxy.cfg

```conf
global
  # Этот параметр указывает HAProxy работать в фоновом режиме как демон
  daemon
  # максимальное количество одновременных подключений к HAProxy
  maxconn 256
# настройки по умолчанию для всех прокси и frontend секций  
defaults
  # HAProxy будет работать как балансировщик для HTTP трафика
  mode http
  # Этот параметр определяет тайм-аут соединения с бэкенд-сервером
  timeout connect 5000ms
  # Этот параметр определяет тайм-аут ожидания клиента. Если клиент не отправит запрос в течение 50000 миллисекунд, то HAProxy закроет соединение.
  timeout client 50000ms
  # Этот параметр определяет тайм-аут ожидания сервера. Если бэкенд-сервер не ответит на запрос в течение 50000 миллисекунд, то HAProxy закроет соединение.
  timeout server 50000ms
# Раздел для ститистики и мониторинга HAProxy  
listen stats
  # Этот параметр указывает на прослушивание всех доступных IP-адресов на порту 9999
  bind *:9999
  # Включение статистики HAProxy.
  stats enable
  # Скрытие версии HAProxy из вывода статистики.
  stats hide-version
  # URI, по которому будет доступна статистика HAProxy.
  stats uri /stats
  # Параметр для аутентификации при доступе к статистике. В данном случае, логин и пароль для доступа к статистике
  stats auth admin:admin@123
# Frontend является первой точкой входа для входящего трафика в HAProxy. Он слушает на определенных портах и принимает запросы от клиентов. 
# Когда клиент отправляет запрос на порт 8080, HAProxy будет прослушивать этот порт на всех доступных IP-адресах и обрабатывать входящие запросы, чтобы распределить их между соответствующими backend-серверами в соответствии с правилами балансировки нагрузки, заданными в конфигурации.
# HAProxy будет принимать HTTP-запросы от клиентов на настроенном порту и далее перенаправлять их на backend-сервер "prom", который был определен в этой же конфигурации.
frontend prom
  # Прослушивание всех доступных IP-адресов на порту 8080
  bind *:8080
  use_backend prom
backend prom
  server prom1 prometheus-1.basov.world:9090 check
  # Опция "backup" указывает, что этот сервер будет использоваться только в случае недоступности первого сервера (prom1).
  server prom2 prometheus-2.basov.world:9090 check backup
```
Данная конфигурация позволяет проксировать запросы c 8080 порта на один из Prom серверов.

Настройка Grafana.
3.1 Добавляем новый data source.
Добавление data source производится аналогично тому, как мы это делали в предыдущей
главе, за исключением адреса сервера. В качестве URL указываем: http://localhost:8080. В
качестве Name указываем: Prometheus HA.

Добавляем dashboard
https://grafana.com/grafana/dashboards/1860

Проверка результатов работы.
Для проверки необходимо выключить Prometheus поочередно на server1 и server2 и
убедиться, что графики продолжают отображаться:
systemctl stop prometheus.service

## Federation
Настраиваем чтобы основной prometheus server собирал информацию с других prometheus серверов


## Хранение данных на удаленных хранилищах. Настройка Remote read/write

Поддерживаемые удаленные хранилища:
AppOptics​: write
Azure Data Explorer​: read and write
Chronix​: write
Cortex​: read and write
CrateDB​: read and write
Elasticsearch​: write
Gnocchi​: write
Graphite​: write
InfluxDB​: read and write
IRONdb​: read and write
Kafka​: write
M3DB​: read and write
OpenTSDB​: write
PostgreSQL/TimescaleDB​: read and write
SignalFx​: write
Splunk​: read and write
TiKV​: read and write
Thanos​: write
VictoriaMetrics​: write
Wavefront​: write

см. слайд

## Thanos (настройка системы для долгосрочного хранения данных)

## API запросы
Коды ответа:
```
2xx – успешный запрос
400 – когда отсутствуют необходимые параметры или они не верные
422 – запрос не может быть выполнен
503 – время ожидания ответа превышено.
Метки времени могут быть переданы либо в формате https://www.ietf.org/rfc/rfc3339.txt, либо в формате Unix timestamp.
```

### Запросы мгновенного вектора
Ednpoint​: /api/v1/query

Method​: GET | POST

Параметры запроса:
- query – строка запроса PromQL.
- time – временная метка, за которую надо выбрать данные. Если параметр не задан, берется текущее время сервера.
- timeout – максимальное время выполнения запроса. Параметр не является обязательным. Если параметр не задан, используется значение query.timeout.

#### GET. Запрос up, время: 19.07.2023 09:10.51
```bash
curl 'http://localhost:9090/api/v1/query?query=up&time=2023-07-20T09:10:51.781Z'
```
Пример аналогичного запроса методом POST:
```bash
curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -d "query=up" -d "time=2023-07-20T09:10:51.781Z" http://localhost:9090/api/v1/query
```

#### Запрос вектора за период времени
Ednpoint​: /api/v1/query_range

Method​: GET | POST

Параметры запроса:
query – строка запроса PromQL.
start – временная метка начала вектора.
end – временная метка окончания вектора.
step – шаг выборки данных; допустимый формат [0-9]+[smhdwy], например 5s, либо число float(секунды).
timeout – максимальное время выполнения запроса. Необязательный параметр. Если параметр не задан, используется значение query.timeout.

Пример.​ Запрос: up, за период с 19.07.2023 10:51.50 по 19.07.2023 10:15.51, с шагом в 30 секунд:
```bash
curl 'http://localhost:9090/api/v1/query_range?query=up&start=2023-07-19T09:10:51.781Z&end=2023-07-19T09:15:51.781Z&step=30s' > zapros
```

#### Поиск временных рядов на основании labels

Ednpoint​: /api/v1/series

Method​: GET | POST

Параметры запроса:
- match[] – задает список меток, соответствие которым учитывается при поиске. Необходимо задать хотя бы одно условие.
- start – временная метка начала вектора.
- end – временная метка окончания вектора.

Пример.​ В результате выполнения запроса мы получим данные по всем временным рядам, которые имеют имя node_disk_write_time_seconds_total и label device со значением sda:
```bash
curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -d 'match[]=node_disk_write_time_seconds_total{device="sda"}' http://localhost:9090/api/v1/series
```
```
-H 'Content-Type: application/x-www-form-urlencoded' - установка заголовка Content-Type в application/x-www-form-urlencoded

-d 'match[]=node_disk_write_time_seconds_total{device="sda"}' - тело запроса в формате x-www-form-urlencoded. match[] задает выражение для поиска временного ряда.
```

```json
{"status":"success","data":[{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"nginx.basov.world:9100","job":"file_sd","sd":"file"},{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"nginx.basov.world:9100","job":"static_config","sd":"static"},{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"prometheus-1.basov.world:9100","job":"file_sd","sd":"file"},{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"prometheus-2.basov.world:9100","job":"file_sd","sd":"file"},{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"vasiliy.basov.world:9100","job":"file_sd","sd":"file"},{"__name__":"node_disk_write_time_seconds_total","device":"sda","instance":"vasiliy.basov.world:9100","job":"static_config","sd":"static"}]}
```
В данном JSON ответе значения самой метрики node_disk_write_time_seconds_total отсутствуют.

В ответе перечислены только метаданные этой метрики для разных временных рядов:

- name - название метрики
- instance - имя инстанции, для которой собирается метрика
- device - имя диска
- job - job из которого собраны данные
- sd - источник данных
Но конкретные числовые значения метрики node_disk_write_time_seconds_total, составляющие временной ряд, здесь не присутствуют.

Чтобы получить эти значения, необходимо в запросе указать дополнительные параметры выборки, например:

Временной диапазон (start, end)
Интервал выборки (step)
Функцию агрегации значений (rate, avg)
Например:

/api/v1/query?query=node_disk_write_time_seconds_total{device="sda"}&start=2019-01-01T00:00:00Z&end=2019-01-02T00:00:00Z&step=1m

Этот запрос вернёт временной ряд фактических значений метрики за указанный период.
#### Получение списка меток (labels)

Endpoint: `/api/v1/labels`

Method: `GET | POST`

Параметры запроса: -

Данный запрос позволяет получить список всех labels. 

Пример:

```bash
curl 'http://localhost:9090/api/v1/labels'
```

Ответ будет примерно таким:

```json
{
  "status":"success",
  "data":[
    "__name__",
    "address", 
    "alertmanager",
    "alertname",
    "alertstate",
    "branch",
    "broadcast",
    "call",
    "code",
    "collector",
    "config",
    "cpu",
    "device",
    "dialer_name",
    "domainname",  
    "endpoint",
    "event",
    "fstype",
    "goversion",
    "handler",
    "instance",
    "interval",
    "job",
    "le",
    "listener_name",
    "machine",
    "mode",
    "mountpoint",
    "name",
    "nodename",
    "operstate",
    "quantile",
    "reason",
    "release",
    "revision",
    "role",
    "rule_group",
    "scrape_job",
    "severity",
    "slice",
    "sysname",
    "version"
  ]
}
```

#### Запрос значений для label

Endpoint: `/api/v1/labels/<label name>/values`

Method: `GET` 

Параметры запроса: -

Данный endpoint позволяет получить все значения для определенного label. 

Синтаксис запроса: 

`/api/v1/labels/<label name>/values`

Где `<label name>` это имя label, для которого необходимо получить значения.

Пример:

```bash
curl 'http://localhost:9090/api/v1/label/instance/values'
```

Ответ будет примерно таким:

```json
{
  "status":"success",
  "data":[
    "129.168.0.7:9090",
    "192.168.0.12:9090", 
    "192.168.0.12:9100",
    "192.168.0.7:9090",
    "192.168.0.7:9100",
    "localhost:9090",
    "localhost:9100"
  ]
}
```

# API для получения конфигурации

### Конфигурация сервера

Endpoint: `/api/v1/status/config`

Method: `GET`

Параметры запроса: -

Данный запрос позволяет получить текущую конфигурацию сервера.

Пример:

```bash
curl 'http://localhost:9090/api/v1/status/config'
```

В ответ будет возвращена конфигурация сервера, в yaml формате.

## Список ключей запуска

Endpoint: `/api/v1/status/flags`  

Method: `GET`

Параметры запроса: -

Данный запрос позволяет получить список ключей и их значений, с которыми в данный момент запущен сервер.

Пример:

```bash 
curl 'http://localhost:9090/api/v1/status/flags'
```

## Список targets

Endpoint: `/api/v1/targets`

Method: `GET`

Параметры запроса: -

Данный запрос позволяет получить информацию о всех targets

Пример:

```bash
curl 'http://localhost:9090/api/v1/targets' 
```

В ответ Вы получите список targets с их параметрами.

# Rules и Alerts API

## Alertmanagers

Endpoint: `/api/v1/alertmanagers`

Method: `GET`

Параметры запроса: -

Данный запрос позволяет получить список всех настроенных alertmanagers и их статус.

Пример:

```bash
curl 'http://localhost:9090/api/v1/alertmanagers'
```

Ответ должен быть примерно таким:

```json
{
  "status":"success",
  "data":{
    "activeAlertmanagers":[
      {
        "url":"http://127.0.0.1:9093/api/v1/alerts"
      },
      {
        "url":"http://192.168.0.7:9093/api/v1/alerts" 
      }
    ],
    "droppedAlertmanagers":[]
  }
}
```

## Alerts

Endpoint: `/api/v1/alerts` 

Method: `GET`

Параметры запроса: -

Данный запрос позволяет получить список активных алертов.

Пример:

```bash
curl http://localhost:9090/api/v1/alerts
```

Ответ должен быть примерно таким:

```json
{
  "status":"success",
  "data":{
    "alerts":[]
  }
}
```

## Rules

Endpoint: `/api/v1/rules`

Method: `GET` 

Параметры запроса: -

Данный запрос позволяет получить список всех правил: как record rules, так и alert rules.

Пример: 

```bash
curl http://localhost:9090/api/v1/rules
```

Ответ должен быть примерно таким:

```json
{
  "status":"success",
  "data":{
    "groups":[
      {
        "name":"...",
        "rules":[
          {
            "name":"...",
            "query":"...",
            ...
          }
        ]
      }
    ]
  }
}
```


# Kubernetes Prometheus

## Install
### install prometheus
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo prometheus-community
```
### Download Chart Localy
```bash 
helm pull prometheus-community/prometheus --untar
```

## values.yaml Prometheus
Описание основных настроек:
```yaml
# Права необходимые для prometheus для работы в кластере (хелм чарт создает необходимые роли и role bunding)
rbac:
  create: true
# Если в кластере уже используется podSecurityPolicy то эту настройку нужно включить 
podSecurityPolicy:
  enabled: false
# Указываем необходимые доступы к private registry. imagePullSecrets позволяет использовать образы Prometheus из закрытых реестров.
imagePullSecrets: []
# - name: "image-pull-secret"

# Количиство реплик. В Production среде должно быть больше одной реплики.
# Если количество реплик больше одного то нужно настроить StatfulSet вместо Deployment
replicaCount: 1

  statefulSet:
    ## If true, use a statefulset instead of a deployment for pod management.
    ## This allows to scale replicas to more than 1 pod
    ##
    enabled: false

    annotations: {}
    labels: {}
    podManagementPolicy: OrderedReady

    ## Alertmanager headless service to use for the statefulset
    ##
    headless:
      annotations: {}
      labels: {}
      servicePort: 80
      ## Enable gRPC port on service to allow auto discovery with thanos-querier
      gRPC:
        enabled: false
        servicePort: 10901
        # nodePort: 10901

# Настройки Prometheus Сервера
server:
  ## Prometheus server container name
  ##
  name: server


  global:
    ## How frequently to scrape targets by default
    ## С какой частотой собираются метрики
    scrape_interval: 1m
    ## How long until a scrape request times out
    ## Через сколько секунд prometheus будет считать что собрать метрики не получилось
    scrape_timeout: 10s
    ## How frequently to evaluate rules
    ## Через какое время правило написанное для alert ов будет считаться выполнившемся.
    evaluation_interval: 1m

  # Настройки отвечающие за настройку внешнего хранилища для метрик
  ## https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write
  ##
  remoteWrite: []
  ## https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_read
  ##
  remoteRead: []
  
  # Настройка ingress контроллера
  ingress:
    ## If true, Prometheus server Ingress will be created
    ##
    enabled: false

    # For Kubernetes >= 1.18 you should specify the ingress-controller via the field ingressClassName
    # See https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/#specifying-the-class-of-an-ingress
    ingressClassName: nginx

    ## Prometheus server Ingress annotations
    ## Если у нас в кластере установлен Cert Manager то мы можем с помощью аннотаций подключить tls сертификат
    annotations: {}
    #   kubernetes.io/ingress.class: nginx
    #   kubernetes.io/tls-acme: 'true'

    ## Prometheus server Ingress additional labels
    ##
    extraLabels: {}

    ## Prometheus server Ingress hostnames with optional path
    ## Must be provided if Ingress is enabled
    ##
    hosts:
      - prometheus.k8s.basov.world
    #   - domain.com/prometheus

    path: /

    # pathType is only for k8s >= 1.18
    pathType: Prefix

    ## Extra paths to prepend to every host configuration. This is useful when working with annotation based services.
    extraPaths: []
    # - path: /*
    #   backend:
    #     serviceName: ssl-redirect
    #     servicePort: use-annotation

    ## Prometheus server Ingress TLS configuration
    ## Secrets must be manually created in the namespace
    ##
    tls: []
    #   - secretName: prometheus-server-tls
    #     hosts:
    #       - prometheus.domain.com

# Обязательно использовать для Production сервера
  persistentVolume:
    ## If true, Prometheus server will create/use a Persistent Volume Claim
    ## If false, use emptyDir
    ##
    enabled: true

    ## If set it will override the name of the created persistent volume claim
    ## generated by the stateful set.
    ##
    statefulSetNameOverride: ""

    ## Prometheus server data Persistent Volume access modes
    ## Must match those of existing PV or dynamic provisioner
    ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
    ##
    accessModes:
      - ReadWriteOnce

    ## Prometheus server data Persistent Volume labels
    ##
    labels: {}

    ## Prometheus server data Persistent Volume annotations
    ##
    annotations: {}

    ## Prometheus server data Persistent Volume existing claim name
    ## Requires server.persistentVolume.enabled: true
    ## If defined, PVC must be created manually before volume will be bound
    existingClaim: ""

    ## Prometheus server data Persistent Volume mount root path
    ##
    mountPath: /data

    ## Prometheus server data Persistent Volume size
    ##
    size: 8Gi

    ## Prometheus server data Persistent Volume Storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ## Прописываем нужный storageClass
    storageClass: "standard-rwo"

    ## Prometheus server data Persistent Volume Binding Mode
    ## If defined, volumeBindingMode: <volumeBindingMode>
    ## If undefined (the default) or set to null, no volumeBindingMode spec is
    ##   set, choosing the default mode.
    ##
    # volumeBindingMode: ""

    ## Subdirectory of Prometheus server data Persistent Volume to mount
    ## Useful if the volume's root directory is not empty
    ##
    subPath: ""

    ## Persistent Volume Claim Selector
    ## Useful if Persistent Volumes have been provisioned in advance
    ## Ref: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector
    ##
    # selector:
    #  matchLabels:
    #    release: "stable"
    #  matchExpressions:
    #    - { key: environment, operator: In, values: [ dev ] }

    ## Persistent Volume Name
    ## Useful if Persistent Volumes have been provisioned in advance and you want to use a specific one
    ##
    # volumeName: ""




  # В Production должна быть больше 1 Реплики 
  ## Use a StatefulSet if replicaCount needs to be greater than 1 (see below)
  ##
  replicaCount: 1

  ## Annotations to be added to deployment
  ##
  deploymentAnnotations: {}

  statefulSet:
    ## If true, use a statefulset instead of a deployment for pod management.
    ## This allows to scale replicas to more than 1 pod
    ##
    enabled: false

    annotations: {}
    labels: {}
    podManagementPolicy: OrderedReady

    ## Alertmanager headless service to use for the statefulset
    ##
    headless:
      annotations: {}
      labels: {}
      servicePort: 80
      ## Enable gRPC port on service to allow auto discovery with thanos-querier
      gRPC:
        enabled: false
        servicePort: 10901
        # nodePort: 10901

  ## Prometheus server resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 500m
      memory: 512Mi

  ## Prometheus data retention period (default if not specified is 15 days)
  ## Сколько времени хранятся метрики в базе данных
  retention: "15d"

## Monitors ConfigMap changes and POSTs to a URL
## Ref: https://github.com/prometheus-operator/prometheus-operator/tree/main/cmd/prometheus-config-reloader
##
# Блок который отвечает за запуск контейнера который перезагружает нашу конфигурацию (без этого контейнера придется после изменения конфигурации перезагружать prometheus руками)
configmapReload:


# Собираеи большое количество метрик
## kube-state-metrics sub-chart configurable values
## Please see https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics
##
kube-state-metrics:
  ## If false, kube-state-metrics sub-chart will not be installed
  ##
  enabled: true

# Собирает метрики наших серверов
## promtheus-node-exporter sub-chart configurable values
## Please see https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter
##
prometheus-node-exporter:
  ## If false, node-exporter will not be installed
  ##
  enabled: true

  rbac:
    pspEnabled: false

  containerSecurityContext:
    allowPrivilegeEscalation: false
```

## alertmanager values.yaml
```yaml
# Количиство реплик. В Production среде должно быть больше одной реплики.
# Если количество реплик больше одного то нужно настроить StatfulSet вместо Deployment
replicaCount: 1

# Имя контейнера (можем поменять если у нас используются приватные registry)
image:
  repository: quay.io/prometheus/alertmanager
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: ""

# Если у нас в кластере используются priorityClass то стоит указать PriorityClass (позволяют выставить приоритет для подов)
# PriorityClass для Production выше, и эти поды будут запускаться быстрее
# Sets priorityClassName in alertmanager pod
priorityClassName: ""

# Настройка Ingress
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: alertmanager.k8s.basov.world
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - alertmanager.domain.com

# Определяем Persistant Volume 
persistence:
  enabled: true
  ## Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ## set, choosing the default provisioner.
  ##
  # Можем прописать StorageClass если он у нас настроен
  storageClass: "standard-rwo"
  accessModes:
    - ReadWriteOnce
  size: 50Mi

# Указываем ресурсы. После запуска системы мониторинга следим за потреблением ресурсов и меняем в случае необходимости
resources:
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 32Mi

# Блок который отвечает за запуск контейнера который перезагружает нашу конфигурацию (без этого контейнера придется после изменения конфигурации перезагружать prometheus руками)
## Monitors ConfigMap changes and POSTs to a URL
## Ref: https://github.com/jimmidyson/configmap-reload
##
configmapReload:
  ## If false, the configmap-reload container will not be deployed
  ##
  enabled: true

  ## configmap-reload container name
  ##
  name: configmap-reload

  ## configmap-reload container image
  ##
  image:
    repository: jimmidyson/configmap-reload
    tag: v0.8.0
    pullPolicy: IfNotPresent

  # containerPort: 9533

  ## configmap-reload resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
```


## prometheus-node-exporter values.yaml

```yaml
# Если мы хотим чтобы node exporter запускался на master нодах то нужно поменять tolerations
# kubectl get nodes
# Смотрим Taints ноды и добавляем в tolerations если хотим установить экспортер на ноду
# kubectl describe node gke-k8s-test-k8s-node-pool-be3fb87b-1vn1 | grep Taints

tolerations:
  - effect: NoSchedule
    operator: Exists

  resources:
    # We usually recommend not to specify default resources and to leave this as a conscious
    # choice for the user. This also increases chances charts run on environments with little
    # resources, such as Minikube. If you do want to specify resources, uncomment the following
    # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
    limits:
      cpu: 100m
      memory: 64Mi
    requests:
      cpu: 10m
      memory: 32Mi
```

## StorageClass и PersistentVolume
```bash
# Посмотреть существующие Storage Classes
# Storage Class может быть динамический и статический. Если Storage Class статический то сначала нужно создать Persistent Volume из манифеста
kubectl get sc
kubectl describe sc standard-rwo
```
```
# Если в результате вывода мы имеем строку
Provisioner:           pd.csi.storage.gke.io
то Storage Class динамический и автоматически создаст Persistent Volume
```
Если Storage Class статический то нам нужно вручную создавать Persistent Volume из манифеста перед установкой helm чарта prometheus

Например:
Предварительно нужно создать папки /local/pv1 на нужных нодах где будут храниться соответствующие Persistent Volume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: node1-pv1
spec:
  capacity:
    storage: 5Gi
  # volumeMode field requires BlockVolume Alpha feature gate to be enabled.
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /local/pv1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node-1.s<ваш номер логина>.slurm.io
```

```bash
# Создаем Persistent Volume
kubectl create pv1.yml
```

```bash
# Посмотреть существующие Persistent Volume
kubectl get pv
```

## Kube-State-Metrics
Это экспортер

Pod
```bash
kubectl describe po -n monitoring prometheus-kube-state-metrics-698464d9bb-qgcks
```
Аргументы с которыми запускается под
```bash
    Args:
      --port=8080
      --resources=certificatesigningrequests,configmaps,cronjobs,daemonsets,deployments,endpoints,horizontalpodautoscalers,ingresses,jobs,leases,limitranges,mutatingwebhookconfigurations,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,poddisruptionbudgets,pods,replicasets,replicationcontrollers,resourcequotas,secrets,services,statefulsets,storageclasses,validatingwebhookconfigurations,volumeattachments
```
### Посмотреть метрики которые собирает Kube-State-Metrics
```bash
curl 10.72.2.12:8080/metrics
```
### Метрики Kube-State-Metrics
Выполняем на prometheus запросы:  
Метрика 
```
kube_deployment_status_replicas_unavailable
```
Показывает количество реплик в статусе недоступные у deployment
Например можем отсылать алерт если эта метрика для важного deployment > 0 :
```
kube_deployment_status_replicas_unavailable{deployment="production-resume-app"}
```

Текущее потребление ресурсов 
```
kube_node_status_capacity{resource="memory"} / 1024
```

Проверяем что совпадает с capacity ноды
```bash
kubectl describe node gke-k8s-test-k8s-node-pool-be3fb87b-1vn1
```

Рекомендуется настроить на production: Количество рестартов подов 
```
kube_pod_container_status_restarts_total > 0
```
Можем составить алерт если pod рестартовал больше двух раз в течениии получаса.

Посмотреть поды которые не имеют статус ready
```
kube_pod_container_status_ready != 1
```
Можем составить алерт на такие поды

## Prometheus config
https://prometheus.io/docs/prometheus/latest/configuration/configuration/

Посмотреть существующие ConfigMap (Хранятся конфигурационные настройки для подов)
```bash
kubectl get cm -n monitoring
```
Открыть ConfigMap для редактирования, это конфиг нашего prometheus сервера
```
kubectl edit cm -n monitoring prometheus-server
```
Здесь мы можем поменять данные и конфиг сохранить. После сохранения произойдет reload конфига. (Если мы его не отключали)

### Секция scrape_configs.
Это инструкция по которой prometheus будет собирать метрики.

#### Job-ы
Посмотреть их можно здесь

http://prometheus.k8s.basov.world/targets

```yaml
    # Имя job-а  
    - job_name: prometheus
      # Способ сбора метрики (статический)
      static_configs:
      - targets:
        - localhost:9090
    - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
```

### Service Discovery
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config

http://prometheus.k8s.basov.world/service-discovery?search=

Динамический сбор данных

#### На примере job kubernetes-apiservers
Нам нужно собирать данные не со всех `endpoints` а только с `API Servers`
```bash
# Просмотр сервисов
kubectl get svc
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.75.240.1   <none>        443/TCP   3d21h

# Просмотр ip адресов API серверов.
kubectl get endpoints
NAME         ENDPOINTS           AGE
kubernetes   10.128.15.199:443   3d21h

# или посмотреть все endpoints
kubectl get ep -A
NAMESPACE       NAME                                  ENDPOINTS                      AGE
default         kubernetes                            10.128.15.199:443              3d21h
kube-system     default-http-backend                  10.72.2.2:8080                 3d21h
kube-system     kube-dns                              10.72.2.9:53,10.72.2.9:53      3d21h
kube-system     metrics-server                        10.72.2.8:10250                3d21h
kube-system     vpa-recommender                       <none>                         3d21h
monitoring      prometheus-alertmanager               10.72.2.14:9093                22h
monitoring      prometheus-alertmanager-headless      10.72.2.14:9093                22h
monitoring      prometheus-kube-state-metrics         10.72.2.12:8080                22h
monitoring      prometheus-prometheus-node-exporter   10.128.15.201:9100             22h
monitoring      prometheus-prometheus-pushgateway     10.72.2.11:9091                22h
monitoring      prometheus-server                     10.72.2.13:9090                22h
nginx-ingress   nginx-ingress-controller              10.72.2.10:443,10.72.2.10:80   3d2h

# Описание Endpoint Kubernetes
kubectl describe ep kubernetes
Name:         kubernetes
Namespace:    default
Labels:       endpointslice.kubernetes.io/skip-mirror=true
Annotations:  <none>
Subsets:
  Addresses:          10.128.15.199
  NotReadyAddresses:  <none>
  Ports:
    Name   Port  Protocol
    ----   ----  --------
    https  443   TCP

```
Нам нужно отфильтровать из этих endpoints только тот который относится к `API Servers `

Как это выглядит в конфиге:
```yaml
      job_name: kubernetes-apiservers
      # Сбор данныых с помощью Service Discovery
      kubernetes_sd_configs:
      # Роль prometheus. Prometheus обращается в Kubernetes API servers и запрашивает у api сервера все объекты типа endpoints. 
      - role: endpoints
      relabel_configs:
        # сохраняем отфильтрованное
      - action: keep
        # (правила фильтрации) здесь мы указываем что мы будем собирать данные только тех endpoints, labels которых соответствует значениям собранным из секции source_labels: т.е __meta_kubernetes_namespace = default __meta_kubernetes_service_name = kubernetes и т.д.
        regex: default;kubernetes;https
        # Мы собираем информацию этих lables со всех endpoints
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
      scheme: https
      # сертификаты для авторизации в API Servers.
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
    - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
```
### Endpoints
`Endpoints` - это объекты `Kubernetes API`, которые содержат информацию о том, как получить доступ к определенному сервису в кластере.

В частности, объект `Endpoints` содержит список IP-адресов и портов всех подов, которые реализуют данный сервис.

Например, если у нас есть сервис `my-service`, то Kubernetes создаст соответствующий объект `Endpoints my-service`, который будет содержать IP и порты подов, предоставляющих функционал этого сервиса.

### Roles
В `Kubernetes Service Discovery` для `Prometheus` есть несколько вариантов `role`, которые можно использовать:

- `endpoints` - используется для сбора метрик с Endpoint объектов Kubernetes. Это позволяет открывать сервисы вроде Kubernetes API server.

- `pod` - используется для сбора метрик непосредственно с подов. 

- `service` - используется для сбора метрик через сервисы Kubernetes. 

- `ingress` - используется для сбора метрик с Ingress контроллеров.

- `node` - используется для сбора метрик с нод Kubernetes (через Kubelet).

Кроме того, есть еще несколько специальных role:

- `pod-list` - открывает все поды, но не собирает с них метрики.

- `endpoints-list` - открывает все Endpoint объекты, но не собирает метрики. 

- `service-list` - аналогично для сервисов.

- `ingress-list` - аналогично для ингрессов.

- `node-list` - аналогично для нод.

Выбор role зависит от того, откуда именно вы хотите собирать метрики в Kubernetes кластере. Например, role `endpoints` хорошо подходит для мониторинга control plane компонентов вроде `API server`, а role `pod` - для сбора метрик с рабочих приложений.

### Control plane 
Control plane (контрольная плоскость) - это набор компонентов, которые отвечают за управление Kubernetes кластером и поддержание его желаемого состояния. Основные компоненты `control plane`:

- `API Server` - предоставляет API для управления кластером, является главной точкой входа для всех запросов управления кластером.

- `etcd` - распределённое хранилище данных, используется API сервером для хранения данных о состоянии кластера и конфигурации. 

- `Scheduler` - отвечает за планирование запуска подов на нодах кластера.

- `Controller Manager` - запускает контроллеры, отвечающие за поддержание состояния разных объектов Kubernetes.

- `Cloud Controller Manager` - взаимодействует с облачным провайдером при использовании Kubernetes в облаке.

Таким образом, `API сервер` - это центральный компонент в `control plane Kubernetes`, который предоставляет всю API и входную точку для управления кластером. Он взаимодействует с остальными компонентами `control plane` для поддержания желаемого состояния кластера и рабочих нагрузок.


### На примере job kubernetes-nodes
```bash
kubectl get nodes
NAME                                       STATUS   ROLES    AGE     VERSION
gke-k8s-test-k8s-node-pool-be3fb87b-1vn1   Ready    <none>   3d21h   v1.26.5-gke.1200
```
Метрики собираются с kubelet. kubelet запущены на всех нодах кластера и kubelet агрегирует некоторое количество метрик.
kubelet свои метрики просто так не отдает, он требует авторизации. Поэтому метрики kubelet мы берем из api servers.
Чтобы получить доступ к метрикам kubelet мы должны обратиться к специальному url api servers
Этот url имеет следующий вид
https://kubernetes.default.svc/api/v1/nodes/gke-k8s-test-k8s-node-pool-be3fb87b-1vn1/proxy/metrics
Посмотреть можно здесь
http://prometheus.k8s.basov.world/targets?search=

Таким образом, эти правила позволяют Prometheus получать метрики нод через API сервер Kubernetes вместо прямого обращения к нодам. Это дает более надежный и масштабируемый подход для мониторинга нод.

```yaml
      job_name: kubernetes-nodes
      # Указывем что используем Service Discovery для сбора метрик
      kubernetes_sd_configs:
      # Запрашиваем из API Servers все текущие ноды
      - role: node
      relabel_configs:
        # создаем новые метки (labels) из собранных меток (labels) ноды. 
      - action: labelmap
        # Указываем какие метки мы собираем. .+ означает "один или более любых символов". Мы берем все метки вида: __meta_kubernetes_node_label_(.+)
        # Посмотреть на метки можно здесь http://prometheus.k8s.basov.world/service-discovery?search=
        regex: __meta_kubernetes_node_label_(.+)
        # Заменяем адрес (это адрес kubelet например __address__="10.128.15.201:10250") на адрес API Servers kubernetes.default.svc:443 из за проблем с авторизацией в kubelet
      - replacement: kubernetes.default.svc:443
        target_label: __address__
      # Берем все значения (.+) из source_labels: __meta_kubernetes_node_name т.е. имя нашей ноды
      - regex: (.+)
        # $1 означает что мы подставляем сюда выражение полученное из regex: (.+)
        replacement: /api/v1/nodes/$1/proxy/metrics
        source_labels:
        - __meta_kubernetes_node_name
        # Записываем получившийся путь в метрику __metrics_path__ 
        target_label: __metrics_path__
        # В результате значение __address__ у нас замениться на kubernetes.default.svc:443 а значени __metrics_path__ на /api/v1/nodes/gke-k8s-test-k8s-node-pool-be3fb87b-1vn1/proxy/metrics
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
```

### На примере job kubernetes-service-endpoints
Сбор метрик с endpoit-ов. т.е. c наших приложений которые мы запускаем в kubernetes
```bash
# Посмотреть service в формате yaml
kubectl get svc -n nginx-ingress nginx-ingress-controller -o yaml
```
Аннотации которые записаны в нашем  yaml манифесте прометеус может замечать и работать с ними
```yaml
metadata:
  annotations:
    meta.helm.sh/release-name: nginx-ingress
    meta.helm.sh/release-namespace: nginx-ingress
```
В prometheus точки и косые линии в аннотациях заменяются нижним подчеркиванием
Эта аннотация meta.helm.sh/release-name в prometheus будет __meta_helm_sh_release_name c которой мы дальше можем работать
Т.е. чтобы фильтровать наши сервисы нам нужно придумать уникальную аннотацию

По умолчанию метрики собираются по протоколу http и по адресу /metrics
Мы должны прописывать нужные аннотации в yaml файле нашего сервиса если хотим поменять это поведение например заменить на https: regex: (https?)
Для этого в наше приложение(endpoint) нужно прописать аннотацию prometheus.io/scheme со значением "https"
http значение по умолчанию для `__scheme__`
Чтобы поменять значение для /metrics по-умолчанию для `__metrics_path__`
нужно прописать нужное значение в сервисе в аннотации prometheus.io/path например значение /monitoring (если метрики находятся по этому пути)

Чтобы prometheus вообще чтонибудь собирал должна быть прописана аннотация prometheus.io/scrape: "true"
```yaml
      job_name: kubernetes-service-endpoints
      kubernetes_sd_configs:
      # Собираем endpoints
      - role: endpoints
      relabel_configs:
      # Здесь мы собираем все endpoints у которых есть аннотаци prometheus.io/scrape: "true"
      # Т.е. чтобы собирать метрики нам достаточно добавить в наш сервис аннотацию prometheus.io/scrape: "true"
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape
      - action: drop
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow
        # заменяем стандартное значение __scheme__ (на http) на значенеи https если в аннотации prometheus.io/scheme прописано значение https
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
        # Заменяем значение стандартного label __metrics_path__ (по-умолчанию /metrics) на значаение прописанное в аннотации endpoint prometheus.io/path
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__
        # Если мы хотим поменять порт для подключения то мы можем прописать аннотацию prometheus.io/port со значением нужного нам порта для сбора метрик
      - action: replace
        regex: (.+?)(?::\d+)?;(\d+)
        # лейблу __address__ применится значение __address__:__meta_kubernetes_service_annotation_prometheus_io_port
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_service_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
        replacement: __param_$1
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: node
    - honor_labels: true

```

Для мониторинга например kube-dns в GKE можем создать специальный сервис для доступа к метрикам
Посмотреть на каком порту собирать метрики 
```bash
kubectl get pod -n kube-system kube-dns-fc686db9b-vhk24 -o yaml
```
находим
```yaml
    ports:
    - containerPort: 10053
      name: dns-local
      protocol: UDP
    - containerPort: 10053
      name: dns-tcp-local
      protocol: TCP
    - containerPort: 10055
      name: metrics
      protocol: TCP
```

kubectl apply -f kube-dns-metrics.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: metrics-sidecar-kube-dns
  labels:
    app: metrics-sidecar-kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "10054" 
    prometheus.io/scrape: "true"
spec:
  clusterIP: None
  ports:
  - name: http-metrics-sidecar
    port: 10054
    protocol: TCP
    targetPort: 10054
  selector:
    k8s-app: kube-dns
```
```yaml
---

apiVersion: v1  
kind: Service
metadata:
  name: metrics-kube-dns
  labels:
    app: metrics-kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "10055"
    prometheus.io/scrape: "true"
spec:
  clusterIP: None
  ports:
  - name: http-metrics-kube-dns
    port: 10055 
    protocol: TCP
    targetPort: 10055
  selector:
    k8s-app: kube-dns
```
## Blackbox Exporter
### На примере job kubernetes-service

Мониторинг с помощью Blackbox Exporter

Если в этой yaml конфигурации мы заменяем blackbox на имя или ip нашего blackbox exporter и в yaml сервиса который мы хотим мониторить мы прописываем аннотацию prometheus.io/probe: "true" то этот job заменит адрес на адрес подходящий для сбора метрик с blackbox exporter

Метрики будут собираться  с этого адреса </br>
http://имя_blackbox_exporter/probe?module=http_2xx&target=имя_сервиса_который_хотим_мониторить

```yaml
      job_name: kubernetes-services
      kubernetes_sd_configs:
      # Запрашиваем все сервисы которые есть у нас в кластере
      - role: service
      # Переназначаем label metrics_path на /probe
      metrics_path: /probe
      params:
        module:
        - http_2xx
      relabel_configs:
      # Мониториться будут только сервисы с аннотацией prometheus.io/probe: "true"
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_probe
      - source_labels:
        - __address__
        target_label: __param_target
      # Здесь вместо blackbox нужно указать конкретное dns имя или ip адрес нашего blackbox сервера   
      - replacement: blackbox
        target_label: __address__
      - source_labels:
        - __param_target
        target_label: instance
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: service
    - honor_labels: true
```
```bash
# install blackbox-exporter
helm pull prometheus-community/prometheus-blackbox-exporter --untar
helm upgrade --install --wait prometheus-blackbox-exporter --create-namespace --namespace monitoring ./prometheus-blackbox-exporter/
```
Проверяем работу exporter-а
http://blackbox.k8s.basov.world/probe?module=http_2xx&target=prometheus.io
или по endpoint-у
http://10.72.0.16:9115/probe?module=http_2xx&target=prometheus.io

```bash
# Зайти внутрь контейнера и посмотреть nslookup
kubectl exec -it -n monitoring prometheus-server-79fbf9cbcd-rpxr7 -- sh
nslookup 10.72.0.16
```
Не нашел dns запись для 10.72.0.16

Прописываем в values.yaml prometheus helm chart наш сервер blackbox.k8s.basov.world
```yaml
      # * `prometheus.io/probe`: Only probe services that have a value of `true`
      - job_name: 'kubernetes-services'
        honor_labels: true

        metrics_path: /probe
        params:
          module: [http_2xx]

        kubernetes_sd_configs:
          - role: service

        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
            action: keep
            regex: true
          - source_labels: [__address__]
            target_label: __param_target
          - target_label: __address__
            # Здесь вместо blackbox нужно указать конкретное dns имя или ip адрес нашего blackbox сервера
            replacement: blackbox.k8s.basov.world
          - source_labels: [__param_target]
            target_label: instance
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: service
```

Дополнительные записи из задания
```yaml
          # Переназначаем label metrics_path на указанный в аннотации манифеста сервиса: prometheus.io/path: /......
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          # Переназначем порт с 80 на порт указанный в аннотации: prometheus.io/serviceport: "8080"
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_serviceport]
            action: replace
            target_label: __address__
            regex: (.+?)(?::\d+)?;(\d+)
            replacement: $1:$2
```

Прописываем в сервисах которые мы хотим мониторить новые аннотации
prometheus.io/probe: "true"
```yaml
apiVersion: v1
kind: Service
metadata:
  name: prom-example-app
  namespace: app
  annotations:
    prometheus.io/serviceport: "80"
    prometheus.io/port: "8080"
    prometheus.io/scrape: "true"
    prometheus.io/probe: "true"
spec:
  selector:
    name: prom-example-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```
```bash
helm upgrade --install --wait prometheus --create-namespace --namespace monitoring ./prometheus
```
Проверяем что конфиг применился
```bash
kubectl edit cm -n monitoring prometheus-server
```
Применяем изменение в манифесте сервиса
```bash
kubectl apply -f example_app/
```
Проверяем что все применилось
```bash
kubectl get svc -n app prom-example-app -o yaml
```
Прверяем что метрики собираются
http://prometheus.k8s.basov.world/targets?search=

Проверяем что эти сервисы доступны
Выполняем PROMQL запрос
probe_success
Должен быть 1

Проверка через curl
```bash
curl -is "http://10.72.0.16:9115/probe?module=http_2xx&target=prometheus-alertmanager.monitoring.svc:9093"
```
или
```bash
curl -is "http://blackbox.k8s.basov.world/probe?module=http_2xx&target=prometheus-alertmanager.monitoring.svc:909
3"
```

## Promtool
Утилита для проверки конфигов и метрик
Можем встраивать в CICD или ansible

## Basic Authorization
Настраиваем авторизацию для Prometheus
https://kubernetes.github.io/ingress-nginx/examples/auth/basic/

https://communities.sas.com/t5/SAS-Communities-Library/Configuring-Basic-Authentication-for-Prometheus-and-Alertmanager/ta-p/788803

/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/basic_auth_for_prom

Создаем пароль в файл auth (здесь пароль admin)
```bash
htpasswd -c auth admin
```
Создаем секрет из файла auth
```bash
kubectl create secret generic basic-auth --from-file auth -n monitoring
```

Прописываем annotations в секции ingress values.yaml
```yaml
    annotations:
    #   kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
      # type of authentication
      nginx.ingress.kubernetes.io/auth-type: basic
      # name of the secret that contains the user/password definitions
      nginx.ingress.kubernetes.io/auth-secret: basic-auth
      # message to display with an appropriate context why the authentication is required
      nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```


## /Federation

Устанавливаем чарт Prometheus для Настройки Federation сервера prometheus из локальной папки prometheus
```bash
helm upgrade --install --wait prometheus-federation --create-namespace --namespace prometheus-federation -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/prometheus_federation/federation.yaml ./prometheus/
```

/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/prometheus_federation/federation.yaml

Endpoint при обращении к которому получаем список всех метрик и их значений в момент обращения

Если у нас есть несколько датацентров и в каждом датацентре у нас есть свой prometheus сервер. Тогда удобно использовать Federation.

Вышестоящий сервер затирает служебные метки instance и job когда собирает метрики с нижестоящих серверов. Чтобы помянять это поведение и сохранить служебные метки:  

`honor_labels: true`  
Сохранение оригинальных значений для всех меток (Если мы например собираем метки с нижестоящих серверов с помощью федерации)

Если мы хотим узнать с какого именно `prometheus` сервера была получена та или иная метрика то прописываем следующую настройку:

Добавление метки сервера `prometheus` ко всем метрикам  
Прописываем на уровне нижестоящего сервера:
```
global: external_labels:
  prom: prom-0
```
Благодоря этой метке мы всегда можем узнать с какого сервера `prometheus` была получена та или иная метрика.


Если нужно подключаться к серверу на котором настроена авторизация то прописываем Basic Auth
```yaml
  prometheus.yml:
    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090

        # Сбор всех метрик с другого prometheus сервера.
      - job_name: federation
        scrape_interval: 30s

        honor_labels: false
        metrics_path: '/federate'

        params:
          # match - является обязательным полем, и в нем указывается фильтр по
          # labels, какие метрики мы хотим получать. Через этот параметр может быть
          # ограничен набор метрик, которые забираются с нижестоящего Prometheus
          match[]:
            - '{job=~".+"}'
        static_configs:
          # указано обращение к Prometheus через имя сервиса
          - targets:
            - prometheus-server.monitoring.svc:80
        # Прописываем аутентификацию если настроена на основном сервере, только если подключаемся через доменное имя   
        # basic_auth:
        #   username: 'admin'
        #   password: 'admin'
```
Тут надо обратить внимание на поля:  

`match` - является обязательным полем, и в нем указывается фильтр по `labels`, какие метрики мы хотим получать. Через этот параметр может быть ограничен набор метрик, которые забираются с нижестоящего `Prometheus`.  

`targets` - в нем указано обращение к `Prometheus` через имя сервиса.

## Долгое хранение данных в prometheus
1) `Victoria Metrics`
2) Настраиваем дополнительный prometheus и собираем метрики с других prometheus серверов с помощью `/federation` но с более низким `scraping interval`.

## Victoria Metrics
Есть `Single Mode` и `Cluster Mode`  
`Single mode` - все в одном бинарнике  
`Cluster Mode` Несколько бинарников

### `Cluster Mode` более гибок и предпочтителен.

Поддерживается репликацию данных из коробки  
Компоненты:
- `vmStorage` - Это tsdb где хранятся наши метрики (Можно масштабировать)
- `vmInsert` - Компонент через который осуществляется запись данных в tsdb (можно маштабировать и создать несколько vmInsert-ов)

- `vmSelect` - компонент для извлечения данных (тоже масштабируется)

- `tenant` - разделение базы данных vmStorage на несколько отдельных баз данных (похоже на namespace)
Мы можем собирать информацию с нескольких `Prometheus` серверов и писать данные в различные `tenant` и они не будут пересекаться.

- `vmAuth` - Аутентификация для кластера  
Позволяет создавать различные учетные данные для различных tenants
- `vmBackup` - Backup (Local, Google Cloud, Amazon S3)
- `vmRestore` - Восстановление
- `vmAlert` + `vmalert-cli` - Аналог Alertmanager
- `vmAgent` - Аналог самого Prometheus, имеет такоже синтаксис

### Установка Victoria Metrics в кластер

https://victoriametrics.github.io/helm-charts/

```bash
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update
```
Получаем values.yaml
```bash
helm show values vm/victoria-metrics-cluster > values.yaml
```
Меняем values.yaml:
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/victoria/values.yaml
Ключевые изменения в values.yml:

Заданы ресурсы для всех объектов
```yaml
  # -- Resource object
  resources:
    limits:
      cpu: 50m
      memory: 64Mi
    requests:
      cpu: 50m
      memory: 64Mi
```

Задан ​podDisruptionBudget​ для всех объектов
```yaml
  # данная настройка влияет на то, сколько Pod может быть одновременно выключено (распространяется только на eviction API). 
  # Она позволяет гарантировать, что при обслуживании кластера Kubernetes не будут выключены все Pod'ы с приложением.
  podDisruptionBudget:
    # -- See `kubectl explain poddisruptionbudget.spec` for more. Ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
    enabled: true
    minAvailable: 1
    # maxUnavailable: 1
    labels: {}
```

Задан podAntiAffinity​
```yaml
  # данная настройка позволяет гарантировать, что Pod из
  # StatefulSet и Pod из Deployment не будут запущены на одной node. Без
  # данной настройки возможна ситуация, когда все Pod будут запущены на
  # одной node, и в случае выхода из строя этой node, кластер останется без
  # мониторинга (Pod для statefulset не перезапускаются автоматически)
  # -- Pod affinity
  affinity:
      podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: vmselect
            topologyKey: kubernetes.io/hostname
```

vmselect.extraArgs ​- добавлены следующие параметры:
```yaml
  extraArgs:
    envflag.enable: "true"
    envflag.prefix: VM_
    loggerFormat: json
    # ограничивает время выполнения запросов
    search.maxQueueDuration: "10s"
    # ограничивает максимальную длину запроса
    search.maxQueryLen: "16384"
    # задает сколько копий time series имеют доступ в vmStorage. Должен совпадать со значением для vmInsert
    replicationFactor: "2"
    # data samples, которое отличаются на значение, указанное в этом поле и менее, будут "дедуплицированы". Этот параметр обязательно использовать при значении ​replicationFactor​ 2 и больше.
    dedup.minScrapeInterval: "1ms"
```

vmInsert.extraArgs ​- добавлены следующие параметры:
```yaml
  extraArgs:
    envflag.enable: "true"
    envflag.prefix: VM_
    loggerFormat: json
    # задает сколько копий time series должны быть сохранены в vmStorage
    replicationFactor: 2
```

vmStorage.StorageClass
```yaml
    # -- Storage class name. Will be empty if not setted
    storageClass: standard-rwo
```

Установка в kubernetes:
```bash
helm upgrade --install vm-cluster vm/victoria-metrics-cluster -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/victoria/values.yaml -n victoria --create-namespace
```
В результате будут установлены следующие компоненты:  
- `vmSelect` - будет установлен как Deployment с значением replicas: 2
- `vmInsert` - будет установлен как Deployment с значением replicas: 2
- `vmStorage` - будет установлен как StatefulSet с значением replicas: 2

#### Настройка Prometheus для Victoria Metrics

То что прописываем в prometheus в values.yaml
```yaml
  # Настройки отвечающие за настройку внешнего хранилища для метрик например victoriametric
  ## https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write
  ##
  remoteWrite:
  - url: http://vm-cluster-victoria-metrics-cluster-vminsert.victoria.svc:8480/insert/0/prometheus/api/v1/write
  ```

URL, куда отправляет данные Prometheus сервер, имеет следующую структуру:  
`/<component>/<clientID>/prometheus/<Prometheus API query>`

- `<component>`​ - префикс для компонента. vmInsert - ​/insert​, `vmSelect - /select`
- `<clientID>`​ - ID клиента, может быть произвольным int и должен совпадать для `insert` и `select` запросов. За счет этого реализуется механизм `tenant`, когда в одну `Victoria Metrics` могут писать различные `Prometheus` сервера и их данные будут хранится в отдельных `tenants` (аналог `namespaсe`)
- `<Prometheus API query>`​ - исходный запрос `Prometheus`.  
Данная структура используется только для `Victoria Metrics` в режиме `​Cluster​`. Если вы используете `Victoria Metrics` в режиме `​Single Node`​, то запросы будут иметь структуру: `​/<Prometheus API query>`

#### Установка dashboards для grafana
kubectl create -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/grafana/victoria_metrics_dashboards -n grafana

Для того, чтобы Grafana увидела новый datasource, нужно перезапустить её Pod
kubectl delete po -n grafana grafana-6f578c8666-t4qgt

## Grafana

https://github.com/grafana/helm-charts/blob/main/charts/grafana/README.md
Скачиваем values.yaml


Меняем настройки
```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  # Должен быть установлен cert manager с настройками 
  # helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.4 --set installCRDs=true --set ingressShim.defaultIssuerName=letsencrypt-prod --set ingressShim.defaultIssuerKind=ClusterIssuer --set ingressShim.defaultIssuerGroup=cert-manager.io
  annotations:
    kubernetes.io/tls-acme: "true"
    # Прописываем Basic Authorization, Предварительно должен быть создан секрет basic-auth с именем и паролем. kubectl create secret generic basic-auth --from-file auth -n monitoring
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
  labels: {}
  path: /

  pathType: Prefix

  hosts:
    - grafana.k8s.basov.world

  extraPaths: []

  # Устанавливаем если установлен cert manager
  tls:
    - secretName: chart-example-tls
      hosts:
      - grafana.k8s.basov.world
```
```yaml
adminUser: admin
adminPassword: grafanapassword
```
```yaml
## Чтобы не слетали настройки при перезапуске графаны
persistence:
  type: pvc
  enabled: true
  # storageClassName: default
  accessModes:
    - ReadWriteOnce
  size: 5Gi
  # annotations: {}
  finalizers:
    - kubernetes.io/pvc-protection
  # selectorLabels: {}
  ## Sub-directory of the PV to mount. Can be templated.
  # subPath: ""
  ## Name of an existing PVC. Can be templated.
  # existingClaim:
  ## Extra labels to apply to a PVC.
  extraPvcLabels: {}

  ## If persistence is not enabled, this allows to mount the
  ## local storage in-memory to improve performance
  ##
  inMemory:
    enabled: false
    ## The maximum usage on memory medium EmptyDir would be
    ## the minimum value between the SizeLimit specified
    ## here and the sum of memory limits of all containers in a pod
    ##
    # sizeLimit: 300Mi
```
root_url - он нужен например для расылки инвайтов на почту где будут генерироваться линки для новых пользователей, для подключения сторонней аутентификации
```yaml
grafana.ini:

  server:
      # The full public facing url you use in browser, used for redirects and emails
    root_url: https://grafana.k8s.basov.world
```

install grafana
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install --wait --atomic grafana grafana/grafana \
  --set adminPassword=grafanapassword \
  --values /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/grafana/values.yaml \
  --create-namespace \
  -n grafana
```

Получить пароль если не устанавливали
```bash
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
kubectl get ingress --all-namespaces
```

### Добавляем New Datasource в Grafana

Data Sources - Add new data source

Выбираем будет ли он default или нет

Прописываем имя сервиса вместе с namespace
Prometheus server URL: http://prometheus-server.monitoring.svc.cluster.local

Save and Test

Идем в Explorer
Code

Вводим Query
kube_deployment_status_replicas_available

Run Query - Проверяем что работает

### Добавляем новый dashboard

`Home` - `Dashboards`  
`New Folder` - `Test` - `Create`: Создаем папку для dashboards  
`New Dashboard `- Нажимаем на иконку "`​механизм​, шестеренка"`:  

Name​: `Our first dash`  
​Description​: `test-test-test`   
Folder: `Test`  
`Save dashboard​.`  

`Add Visualization`

- Создаем две метрики с учетом будущего подключения фильтрации по `namespaces`

  `kube_deployment_status_replicas_available{namespace=~"$Namespace"}`  
  Legend:  
  `Available: {{ deployment }}, ns: {{namespace}}`

  `kube_deployment_status_replicas_unavailable{namespace=~"$Namespace"}`  
  Legend:  
  `Unavailable {{ deployment }} ns: {{namespace}}`


- Создадим вторую `Visualization панель`  
Выберем метод отображения `gauge`  
`kube_deployment_status_replicas_available{namespace=~"$Namespace"}`
  Legend:  
`{{ deployment }}` Type: Instant  (Последнее значение)
Value Option - Calculate - Last

- Настройим фильтрацтю по `namespace`  
Создадим переменную, по которой можно будет фильтровать метрики по `namespace`.

  `Dashboard settings` - `variables` - `New Variable`

  Variable Type: `Query`  
  Name: `Namespace`  
  Show on dashboard: `Label and value`  
  `Query options`:  

      Data source: `Prometheus`  
      Query type: `Label values`  
      Label: `namespace`  
      Metric: `kube_deployment_status_replicas_available`  
      Label filters: `Select label` - `select value`  

      `On time range change`  
      `multi-value`: галка +  
      `include All option:` галка +  

  Фильтрация будет происходить если в конец метрики добавить  
  `​{namespace=~"$Namespace"}`

- Поставим самый популярный дашборд.
  https://grafana.com/grafana/dashboards/
  Node Exporter Full
  
  Dashboards - New - Import  
  Import via grafana.com: 1860

- `Plugins`
  Можете перейти на сайт и просмотреть какие есть плагины -
  https://grafana.com/grafana/plugins

  У каждого плагина есть инструкция по установке.  
  Мы будем устанавливать плагин - `Pie Chart` (В нынешней версии графаны уже есть по-умолчанию). Давайте же приступим.  
  Посмотрим вывод команды  
  `watch kubectl get po,ing,secrets,svc -n monitoring`  
  Возьмем имя пода с grafana'ой, у меня это - `​pod/grafana-56dd55f874-nlmwf` ​и зайдем в этот под.  
  `k exec -ti pod/grafana-56dd55f874-nlmwf bash -n monitoring`  
  Вводим команду на установку плагина - `Pie Chart`  
  `grafana-cli plugins install grafana-piechart-panel`

  Выйдем из пода.  
  Удалим под, чтобы новый под уже был с нашим плагином.  
  `k delete pod/grafana-56dd55f874-nlmwf -n monitoring`

### Работа с пользователями в Grafana

`Роли`:
  - `viewer`
  - `editor`
  - `admin`

`Teams`  
Пользователей можно добавлять в `teams` и добавлять teams права

`ORGs`  
Организации, самый высокоуровневый способ разграничения доступа

Настройка  
`Administration` - `Users` - `New user`
Или через Invite
`Administration` - `Users` - `Organization users` - `Invite` - Вводим данные - `Submit`
`Organization users` - `Pending Invites` - `Copy invite` - `Можем послать пользователю`

Organizations - Main Orgs - Change Role - Можем сменить роль

### Как преобразовать числовое unix время в нормальный формат
https://community.grafana.com/t/convert-epoch-metric-to-datetime/101086/6

Teams - New team - Вводим данные - 

Можем раздавать доступы для пользователей и команд на папки dashboards в разделах permission
Можем создавать новые организации, в новой организации ничего нет, выбирать организации в левом верхнем углу. 

В разные организации можно добавлять одних и тех же пользователей.

Grafana умеет работать с внешними OAuth сервисами например GitHub, умеет работать с LDAP.

Authentification прописывается в values.yaml

Например для Github
```yaml
 https://grafana.com/docs/grafana/latest/auth/github/#enable-github-in-grafana
 auth.github:
    enabled: true
    allow_sign_up: true
    scopes: user:email,read:org
    auth_url: https://github.com/login/oauth/authorize
    token_url: https://github.com/login/oauth/access_token
    api_url: https://api.github.com/user
    # 
    team_ids:
    # Вводим организацию в Github у которой будут права на доступ к Grafana:
    allowed_organizations: devopsprodigy
    # Эти параметры создаем на странице Github:
    client_id:
    client_secret:
```

Появится кнопка `Sign in with GitHub`

### Provisioning

Директория находится здесь:
provisioning: /etc/grafana/provisioning  
values.yaml:

```yaml
grafana.ini:
  paths:
    data: /var/lib/grafana/
    logs: /var/log/grafana
    plugins: /var/lib/grafana/plugins
    provisioning: /etc/grafana/provisioning
```
При старте графаны все конфигурации будут подтягиваться из этого каталога

Секция plugins, с какими плагинами grafana будет запускаться:
```yaml
plugins: []
```

Набор Datasources при запуске

```yaml
datasources: {}
```

dashboads:
```yaml
dashboards: {}
```

#### Provisioning Datasorces

Добавим на Datasource Через values.yaml и удалим старый

```yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.monitoring.svc.cluster.local
      access: proxy
      isDefault: true
#    - name: CloudWatch
#      type: cloudwatch
#      access: proxy
#      uid: cloudwatch
#      editable: false
#      jsonData:
#        authType: default
#        defaultRegion: us-east-1
    deleteDatasources:
    - name: Prometheus
```
И обновляем графану
```bash
helm upgrade --install --wait --atomic grafana grafana/grafana --set adminPassword=grafanapassword --values /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/grafana/values.yaml --create-namespace -n grafana
```

Сделаем новую переменную для выбора Datasource

Наш Dashboard - Settings - Variables:  
Select variable type: Data Source

Data source options
Type: Prometheus - тип наших Datasources
Apply

Заходим в Visualization - Data source

#### Provisioning plugins

Добавим plugin через values.yaml  
https://grafana.com/grafana/plugins/smartmakers-trafficlight-panel/

Копируем его имя в секции installations  
smartmakers-trafficlight-panel

Добавляем
```yaml
## Pass the plugins you want installed as a list.
##
plugins:
  - smartmakers-trafficlight-panel
```

Проверяем что plugin появился  
Home - Administration - Plugins -TrafficLight


#### Provisioning Dashboards

После того как мы сделали dashboard, идем в 
Значек сверху   
Share dashboard or panel - Export - Export for sharing externally вкл. - Save to File


Почему то не заработало как должно:
Можно добавлять в RAW форматк также
```yaml
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'monitoring'
      orgId: 1
      folder: 'monitoring'
      type: file
      disableDeletion: true
      editable: true
      options:
        # Пути где находятся Dashboards
        path: /var/lib/grafana/dashboards/default

## Configure grafana dashboard to import
## NOTE: To use dashboards you must also enable/configure dashboardProviders
## ref: https://grafana.com/dashboards
##
## dashboards per provider, use provider name as key.
##
dashboards:
  # Имя dashboardProvider (Папки в Grafana)
  monitoring:
    custom-dashboard:
      file: dashboards/pie_chart2.json
    # Имя Дашборда
    node-exporter:
      gnetId: 1860
      revision: 32
      datasource: "Prometheus"
```

## Prometheus Operator

`Prometheus Operator`- это проект в экосистеме Kubernetes, который предоставляет автоматизированный и управляемый способ развертывания, настройки и масштабирования сервера мониторинга Prometheus и связанных компонентов в кластере Kubernetes.

Prometheus Operator управляет кастомными ресурсами Kubernetes CustomResourceDefinition (CRD), в кластере kubernetes.

CRD, это фактически расширение API Kubernetes, позволяя создавать и управлять своими собственными объектами через Kubernetes API сервер.

`Prometheus Operator CRD`
1. `Prometheus` - описывает установку Prometheus
2. `Alertmanager` - описывает установку Alertmanager
3. `ServiceMonitor` - Аналог service discovery (прописываем аннотации в поды чтобы он мониторился в Prometheus), описывает за какими сервисами нужно следить, какие порты должны использоваться в этом сервисе, как часто нужно делать scrape по какому endpoint находятся метрики... На основе этого он генерирует конфигурационный файл, для Prometheus Scraping.
4. `PodMonitor` - тоже самое только для pod, потому что не все поды имеют сервисы
5. `Probe` - Описывает список Ingress для добавления в мониторинг, например для BlackBox Exporter.
6. `PrometheusRule` - описывает набор Rules (Правил), которые будут добавлены в Prometheus Аналог ServiceMonitor
7. `AlertManagerConfig` - описывает набор Alerts которые будут добавлены в Prometheus

### Grafana
Чтобы загрузить новые dashboards или datasources в графану, нужно прописать `ConfigMaps` с определенными аннотациями. И контейнеры в pod с grafana отслеживают ConfigMaps с определенными аннотациями и монтируют эти ConfigMaps графане.

### Prometheus Про что важно не забыть
1. `Prometheus` нужно устанавливать минимум в 2 копии, потому что он StatefulSet
2. Нужно настраивать basic auth
3. retension size - ограничение размера данных которые он хранит.
4. Alertmanager - минимум в 3 копии
5. Alertmanager - authenrification
6. Grafana - dashboards храним только в git и подгружаем их отдельно в виде configmaps.

### Установка

```bash
# Prometheus Operator Install
helm repo update
kubectl create ns prometheus-operator
# Create Secret for basic auth
htpasswd -c auth admin
kubectl create secret generic admin-basic-auth --from-file=auth -n prometheus-operator
# Проверка
kubectl get secrets -n prometheus-operator admin-basic-auth

helm upgrade --install prom-operator prometheus-community/kube-prometheus-stack --namespace prometheus-oper --create-namespace -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/prometheus_operator/changed_values.yaml
```

### Настройка Servicemonitor и Podmonitor

#### Servicemonitor

Servicemonitor - это абстракция, с помощью которой реализован механизм Service discovery в Prometheus Operator. В данной абстракции описывается, из каких Service необходимо получить список Endpoint, и задаются правила, по которым необходимо производить scraping. В общем случае манифест Servicemonitor выглядит примерно так:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: prom-kube-prometheus-nodexporter
spec:
  # содержит настройки, по которым должен производиться
  # scraping, такие как: частота опроса, endpoint, может быть указан
  # аутентификация, настройки tls и так далее.
  endpoints:
  - interval: 1m
    path: /metrics
    # задается порт, по которому будет производиться
    # scraping. Важной особенностью является то, что Servicemonitor работает
    # только с именованными портами, то есть указать port: 443 нельзя.
    port: metrics-port
  # задает, в каком namespace будет производиться
  # scraping. Возможные значения: matchNames и any: true/false. В случае
  # использования any: true будет производиться по всем namespace.
  namespaceSelector:
    matchNames:
      - prometheus-operator
  # содержит настройку, какие labels должна содержать служба,
  # для которой будет получаться список endpoints. Может содержать следующие параметры:
  selector:
    # список labels, которые должны быть у службы.
    matchLabels:
      app: example
    # matchExpressions - регулярное выражение для discovery Service на основании наличия или отсутствие labels. Формат регулярных выражений:
    # - key: serviceapp
    #   operator: Exists
```

Полный список полей можно посмотреть здесь:  
https://docs.openshift.com/container-platform/4.4/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html  

#### PodMonitor

PodMonitor - это абстракция, с помощью которой реализован механизм Service
discovery в Prometheus Operator. В данной абстракции описываются, какие Pod
необходимо добавить в Prometheus и правила, по которым необходимо
производить scraping. В общем случае, манифест PodMonitor выглядит примерно
так:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: example-app
spec:
  # задает, в каком namespace будет производиться scraping Возможные значения: ​matchNames​ и ​any: true/false​. В случае использования ​any: true​ будет производиться по всем namespace.
  namespaceSelector:
    matchNames:
      - prometheus-operator
  # содержит настройку, какие метки должна содержать служба, для которой будет получаться список endpoints. Может содержать следующие параметры: ​matchNames​ и ​any: true/false​. В случае использования ​any: true будет производиться по всем namespace.
  selector:
    matchLabels:
      app: example
  # содержит описание, какие порты должны использоваться для scraping, а также другие настройки, относящиеся к scraping.
  podMetricsEndpoints:
  - port: web
  honorLabels: true
```

Полный список полей можно посмотреть здесь:  
https://docs.openshift.com/container-platform/4.4/rest_api/monitoring_apis/podmonitor-monitoring-coreos-com-v1.html

### Что делать если закончилось место для prometheus, как расширить PVC?

Инструкция https://prometheus-operator.dev/docs/operator/storage/#resizing-volumes

Применяем изменения:
```yaml
prometheus:
  prometheusSpec:
# Меняем настройку paused на true
    paused: true
    retentionSize: "500MB"
    replicas: 1
# Меняем настройку Storage на нужный нам объем
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: standard-rwo
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
```

```bash
# Resize Persistent Volume Claim (PVC) Prometheus Operator
# PVC должны быть связаны иначе будет ошибка spec is immutable after creation except resources.requests for bound claims
# -l здесь значит pvc с нужным нам label
for p in $(kubectl get pvc -l operator.prometheus.io/name=prom-operator-kube-prometh-prometheus -n prometheus-oper -o jsonpath='{range .items[*]}{.metadata.name} {end}'); do \
  kubectl -n prometheus-oper patch pvc/${p} --patch '{"spec": {"resources": {"requests": {"storage":"5Gi"}}}}'; \
done
```

У меня и без этого заработало:
```bash
# delete the underlying StatefulSet using the orphan deletion strategy
kubectl delete statefulset -n prometheus-oper -l operator.prometheus.io/name=prom-operator-kube-prometh-prometheus --cascade=orphan
```

Применяем изменения назад:
```yaml
prometheus:
  prometheusSpec:
# Меняем настройку paused на true
    paused: false
```

### Ставим на мониторинг Nginx ingress сервис 

Сначала нужно включить метрики в nginx ingress

Чтобы метрики появились нужно добавить `--set controller.metrics.enabled=true` в nginx ingress  
https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx

Проверяем что метрики появились:  
Должен появится новый сервис ingress-nginx-controller-metrics

Делаем curl с любой ноды
```bash
curl 10.76.11.44:10254/metrics
```

Создаем ServiceMonitor  
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
# Чтобы метрики появились нужно добавить --set controller.metrics.enabled=true в nginx ingress
# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
metadata:
  name: prom-kube-prometheus-nginx
  annotations:
    meta.helm.sh/release-name: prom-operator
    meta.helm.sh/release-namespace: prometheus-oper
  labels:
    app.kubernetes.io/instance: prom-operator
    app.kubernetes.io/name: nginx-ingress
    app: nginx-ingress
    component: controller
    release: prom-operator
spec:
  # список labels, которые должны быть у службы которую мы будем мониторить.
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  endpoints:
  - port: metrics
    interval: 1m
    path: /metrics
  jobLabel: prom-operator
  namespaceSelector:
    matchNames:
      - ingress-nginx
```

Применяем
```bash
kubectl apply -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/prometheus_operator/servicemonitor_ingress.yaml -n prometheus-oper
```

Проверяем в prometheus что метрики собираются:  
nginx_ingress_controller_response_size_sum

### Настройка Prometheus rules

Нужны для агрегации данных и создания новых метрик на основе существующих данных.

Также Создание правил мониторинга позволяет настраивать автоматическое масштабирование вашего приложения на основе метрик. Например, вы можете создать правило, которое автоматически увеличивает количество ресурсов, выделяемых приложению, если определенная метрика превышает порог.

Custom resource `PrometheusRule` достаточно простой, он содержит стандартные
поля Kubernetes абстракции, а в поле spec описываются Rules с таким же
синтаксисом, как и у Prometheus. В общем случае, `PrometheusRule` выглядит
примерно так:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: prometheus-example-rules
spec:
  # Определяем группу правил
  groups:
  - name: node.rules
  # Правила
  rules:
  - expr: sum(min(kube_pod_info{node!=""}) by (cluster, node))
    record: ':kube_pod_info_node_count:'
  - expr: |-
    topk by(namespace, pod) (1,
      max by (node, namespace, pod) (
        label_replace(kube_pod_info{job="kube-state-metrics",node!=""}, "pod", "$1", "pod", "(.*)")
    ))
    record: 'node_namespace_pod:kube_pod_info'
```


Создаем свое правило


Создайте `PrometheusRule` с именем: `​prom-ingress.rules`​,
который вычисляет выражение: ​rate`(nginx_ingress_controller_requests[5m])`
и сохраняет его с именем: `​nginx_ingress_controller_requests_per_second`​.
Имя группы: `​Ingress`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: prom-ingress.rules
  annotations:
    meta.helm.sh/release-name: prom-operator
    meta.helm.sh/release-namespace: prometheus-oper
  labels:
    app.kubernetes.io/instance: prom-operator
    release: prom-operator
spec:
  groups:
  - name: Ingress
    rules:
    - expr: rate(nginx_ingress_controller_requests[5m])
      record: nginx_ingress_controller_requests_per_second
```

Применяем
```bash
kubectl apply -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/prometheus_operator/prometheusrule_ingress.yaml -n prometheus-oper
```

Проверить что правило появилось
https://prometheus.kubernetes.basov.world/rules
или запрос `nginx_ingress_controller_requests_per_second`

## Логи Kubernetes (EFK) или (Loki Promtail Grafana)

Посмотреть логи с помощью kubernetes:
```bash
k logs -n kube-system kube-dns-5bfd847c64-hmtjt
```

Логи хранятся на нодах в директории
`/var/log/pods/`
и  
`/var/log/containers/`

Логи общепринято забирают с `/var/log/pods/`

Например:
```bash
cat /var/log/pods/ingress-nginx_ingress-nginx-controller-5b9d6f6bb-dtrjj_a96e5282-3eb0-4152-9ad2-6ab6c3c6169f/controller/0.log
```

Мы можем собирать все логи как логи подов кроме логов `kubelet` и логи `docker` которые мы можем собрать с помощью:

```bash
journalctl -u kubelet
journalctl -u docker
```

### Проблема логов kubernetes

1. При пересоздании pods логи этих pods тоже удаляются (Предыдущие версии)  
2. Мы хотим агрегировать логи с нескольких инстансов.
3. Добавлять Мета информацию (например с какой ноды логи в каком namespace)
4. Парсить (Выделять набор полей в логах и разделять логи по уровню важности)

### FluentD и FluentBit
написаны одним разраюотчиком  
`fluentd` более тяжеловесный написан на более медленном языке и меньше подходит для `kubernetes`.

В облаках обычно используют `FluentBit` (Агент сборщика логов)

Сборщика устанавливаем с помощью `DeamonSet` чтобы он был на каждой ноде.

### Loki Promtail Grafana

`FluentBit` Заменяем на `PromTail`
`Loki` - продукт для логирование от `Grafana` - гораздо более легковесны и лучше чуыствует себя в кластере kubernetes, но он не предназначен для огромных инфраструктур. 
Хороша для небольших кластеров. (Проще и удобнее чем ElasticSearch)

### Установка EFK

#### См. ниже как ставить версию 7.17.3

#### Установка ElasticSearch
```bash
helm repo add elastic https://helm.elastic.co
helm repo update
helm search repo elastic
helm show values elastic/elasticsearch > elastic_original_values.yaml
```
Elastic search values

```yaml
replicas: 3
# Потребляет много ресурсов потому что написана на Java
# Для Production опреативки нужно больше 4-8 Gb и "-Xmx1g -Xms1g" соответственно тоже больше 
# Эти значения должны быть в два раза меньше чем мы устанавливаем для оперативной памяти resources
esJavaOpts: "-Xmx1g -Xms1g"

resources:
  requests:
    cpu: "1000m"
    memory: "2Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

# Меняем под наши нужды storage
volumeClaimTemplate:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 5Gi

# Enabling this will publicly expose your Elasticsearch instance.
# Only enable this if you have security enabled on your cluster
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    # Секрет должен быть создан заранее с именем admin-basic-auth'
    nginx.ingress.kubernetes.io/auth-secret: admin-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
    kubernetes.io/tls-acme: "true"
    acme.cert-manager.io/http01-edit-in-place: "true"

  # kubernetes.io/ingress.class: nginx
  # kubernetes.io/tls-acme: "true"
  className: "nginx"
  pathtype: ImplementationSpecific
  hosts:
    - host: elasticsearch.kubernetes.basov.world
      paths:
        - path: /
  tls:
    - secretName: elasticsearch-general-tls
      hosts:
        - elasticsearch.kubernetes.basov.world
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local
```

Установка: В продакшене рекомендуется выносить `elasticsearch` на отдельные ноды (отдельные сервера), если логов много то перед `elasticsearch` еще ставят `Kafka` а потом с помощью `fluentd` или `logstash` перекладывают их в `elasticsearch` если он не успевает обрабатывать логи.

```bash
helm upgrade -i elasticsearch elastic/elasticsearch -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/elastic_changed_values.yaml -n logging --create-namespace
```
Дождитесь пока все поды запустятся и станут Ready:
```bash
kubectl get pods --namespace=logging -w
```

Посмотреть Login и Password можно в Secrets:
elasticsearch-master-credentials

#### Установка версии elasticsearch 7.10.2

Последняя opensource версия, не ставиться если просто указать версию для kubernetes 1.25 и выше из за ошибки 

```bash
no matches for kind "PodDisruptionBudget" in version "policy/v1beta1" elasticsearch
```

PodDisruptionBudget должен быть версии "policy/v1"

Установка 7.10.2: 

```bash
helm pull elastic/elasticsearch --version 7.10.2 --untar
# Меняем версию PodDisruptionBudget на "policy/v1" в /templates/poddisruptionbudget.yaml
# Ставим
helm upgrade -i elasticsearch -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/elastic_changed_values.yaml -n logging --create-namespace ./elastichelmchart7.10.2/
```

#### Установка версии elasticsearch 7.17.3

```bash
helm show values elastic/elasticsearch --version 7.17.3 > elastic_original_values7.17.3.yaml
helm upgrade -i elasticsearch elastic/elasticsearch --version 7.17.3 -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/elastic_changed_values.yaml -n logging --create-namespace
```

#### Установка FluentBit

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm search repo fluent
helm show values fluent/fluent-bit > fluent_bit_original_values.yaml
```

```yaml
# kind -- DaemonSet or Deployment
# Поды распространяются по всем нодам в кластере
kind: DaemonSet

# С помощью аннотаций можем поставить cборщики на мониторинг в prometheus
# Для продакшена нужно поставить
service:
  type: ClusterIP
  port: 2020
  loadBalancerClass:
  loadBalancerSourceRanges: []
  labels: {}
  # nodePort: 30020
  # clusterIP: 172.16.10.1
  annotations: {}
#   prometheus.io/path: "/api/v1/metrics/prometheus"
#   prometheus.io/port: "2020"
#   prometheus.io/scrape: "true"

# Настройка алертов
prometheusRule:
  enabled: false
#   namespace: ""
#   additionalLabels: {}
#   rules:
#   - alert: NoOutputBytesProcessed
#     expr: rate(fluentbit_output_proc_bytes_total[5m]) == 0
#     annotations:
#       message: |
#         Fluent Bit instance {{ $labels.instance }}'s output plugin {{ $labels.name }} has not processed any
#         bytes for at least 15 minutes.
#       summary: No Output Bytes Processed
#     for: 15m
#     labels:
#       severity: critical
# 
dashboards:
  enabled: false
  labelKey: grafana_dashboard
  labelValue: 1
  annotations: {}
  namespace: ""

# Прописываем tolerations чтобы fluent-bit ставился на все ноды (в том числе ноды с taints, master ноды)
tolerations:
  - operator: Exists
    effest: NoSchedule

# Обязательно нужно прописать ресурсы в production
resources: {}
#   limits:
#     cpu: 100m
#     memory: 128Mi
#   requests:
#     cpu: 100m
#     memory: 128Mi

## https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/classic-mode/configuration-file
# Основная конфигурация FluentBit
config:

```

```bash
helm upgrade -i fluent-bit fluent/fluent-bit -n logging --create-namespace -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/fluent_bit_changed_values.yaml
```

#### Установка FluentBit 0.20.0

```bash
helm show values fluent/fluent-bit --version 0.20.0 > fluent_bit_changed_values0.20.0.yaml
helm upgrade -i fluent-bit fluent/fluent-bit --version 0.20.0 -n logging --create-namespace -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/fluent_bit_changed_values.yaml
```

Ошибки в подах fluent-bit
```bash
[2023/11/12 17:50:56] [error] [output:es:es.1] HTTP status=429 URI=/_bulk, response:
{"error":{"root_cause":[{"type":"es_rejected_execution_exception","reason":"rejected execution of coordinating operation [coordinating_and_primary_bytes=52703926, replica_bytes=0, all_bytes=52703926, coordinating_operation_bytes=2267981, max_coordinating_and_primary_bytes=53687091]"}],"type":"es_rejected_execution_exception","reason":"rejected execution of coordinating operation [coordinating_and_primary_bytes=52703926, replica_bytes=0, all_bytes=52703926, coordinating_operation_bytes=2267981, max_coordinating_and_primary_bytes=53687091]"},"status":429}
```
Это сообщение об ошибке означает, что запрос к `Elasticsearch` был отклонен с кодом состояния `HTTP 429` `(Too Many Requests)`. `Elasticsearch` возвращает этот код состояния, когда сервер считает, что он превысил ограничения на количество запросов или ресурсов, и он временно не может принимать больше запросов.

Причина отказа в выполнении `(es_rejected_execution_exception)` указывает на то, что `Elasticsearch` отклонил запрос из-за ограничений по ресурсам. Судя по сообщению, это может быть связано с тем, что достигнут лимит ресурсов, который `Elasticsearch` может использовать для выполнения операций координации.
```bash
helm upgrade -i kibana elastic/kibana -n logging --create-namespace -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/kibana_changed_values.yaml
```

#### Установка Kibana

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
helm search repo elastic
helm show values elastic/kibana > kibana_original_values.yaml
```

Посмотреть Login и Password можно в Secrets:
elasticsearch-master-credentials

Заходим в Kibana
Management - Stack Management 

#### Установка Kibana 7.17.3

```bash
# Create Secret for basic auth
htpasswd -c auth admin
kubectl create secret generic admin-basic-auth --from-file=auth -n logging
```

```bash
helm show values elastic/kibana --version 7.17.3 > kibana_original_values7.17.3.yaml
helm upgrade -i kibana elastic/kibana --version 7.17.3 -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/efk/kibana_changed_values.yaml -n logging --create-namespace
```


#### Настройка kibana

Home - Management - Stack Management  
Kibana - Index Patterns  
Create Index Patterns

Мы видим что в elasticsearch есть два индекса:  
```
logstash-2023.11.12
node-2023.11.12
```
Эти индексы ротируются каждый день. Т.е. каждый день создается новый индекс. Поэтому логи за несколько дней будут лежать в нескольких индексах и нам нужно объяснить kibana что все индексы node-* это все индексы в которых хранятся наши node логи.


#### Сбор логов с node  
В Create index pattern  
Name 
```text
node-*
```
Timestamp field
```text
@timestamp
```

Create Index Pattern

Все индекс создался.

Analytics - Discover  
Видим логи, все логи от компонента kubelet

#### Сбор логов с наших приложений в кластере
В Create index pattern  
Name 
```text
logstash-*
```
Timestamp field
```text
@timestamp
```

Create Index Pattern
Все индекс создался.

Analytics - Discover 

После того как изменим префмкс в конфиге fluent-bit
```yaml
  outputs: |
    [OUTPUT]
        Name es
        Match kube.*
        Logstash_Prefix kube
```
Нам нужно поменять наш index pattern
index pattern logstash-* в kibana на kube-*

Home - Management - Stack Management  
Kibana - Index Patterns  
logstash-* - этот паттерн удаляем

В Create index pattern  
Name 
```text
kube-*
```
Timestamp field
```text
@timestamp
```

Create Index Pattern
Все индекс создался.

Analytics - Discover Проверяем что логи появились


### Работа в kibana

Analytics - Discover - Search - используем KQL - kibana query language 

Примеры:  
1. Найти все логи подов kibana
```KQL
kubernetes.pod_name: kibana*
```
2. Выражения можно объединять. Есть ключевые слова and, or, not их можно объединять с помощью скобок.
```KQL
kubernetes.pod_name: kibana* and res.statusCode: 200
```

3. 
```KQL
kubernetes.pod_name: kibana* and res.statusCode: < 500
```

Если мы хотим видеть только определенные поля то слева в секции `Available fields` можем выбрать эти поля и добавлять их в `Selected fields` с помощью плюсика.


#### Dashboards
Analytics - Dashboards
Логи должны быть отпарсены

Create new dashboard - create visualization 
search field вводим : req.method.keyword перетаскиваем на визуализацию, меняем отображение на stacked (over time) здесь мы можем посмотреть наши запросы по типам за какое то определенное время.


## Loki Promtail Grafana

Локи лучше использовать на ненагруженных проектах

### Установка Loki

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm show values grafana/loki > loki_original_values.yaml

helm upgrade -i loki grafana/loki -f  /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/loki_promtail_grafana/loki_changed_values.yaml --create-namespace -n logging
```

### Установка Promtail

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm show values grafana/promtail > promtail_original_values.yaml
helm upgrade -i promtail grafana/promtail -f /home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/loki_promtail_grafana/promtail_changed_values.yaml --create-namespace -n logging
```

### Настраиваем Grafana

Home - Datasource - Add new data source - Loki
logging это namespace
URL: http://loki.logging:3100

save and test

Home - Explore - code
Сделаем запрос:  
Получем все логи подов ingress-nginx  
```text
{namespace="ingress-nginx"}
```

Все логи содержащие слово POST  
```text
{namespace="ingress-nginx"} |= "POST"
```

Можем использовать regexp с ~  
Запрос где слово POST есть в теле сообщения  
```text
{namespace="ingress-nginx"} |~ "POST .*"
```

## Мониторинг что мониторить?

1. Бизнес метрики - в первую очередь  
Поведение пользователей  
Количество регистраций  

2. Метрики приложений  
Использование памяти  
`Данные из Баз Данных` - (Postgres Exporter, умеет также делать кастомные запросы из баз данных и значения этих запросов как значения метрик - самый используемый метод в бизнесе, идеальный вариант поднимать реплику (асинхронную) базы данных и из нее делать запросы)  
`Данные из сценариев` - сервис авторизации (например `script exporter` который может выполнять любые скрипты написанные на bash и возвращать результат их выполнения) с помощью такого скрипта можно полностью повторять действия пользователя который совершает действия в нашей системе и мониторить видеть проблемы в системе
`Данные из приложений` - библиотеки которые есть у prometheus для языков програмирования (документация prometheus). Разработчики должны предоставлять данные из приложений в систему мониторинга.

3. Метрики кластера  
`ETCD` - ETCD доступен, как часто у etcd меняются мастера.  
`Control Plane` - kube api server, controller manager, scheduler, kubelet, kube proxy  
Docker (или containerd)  
CoreDNS - сколько запросов проходит в coreDNS и соотносить это с потреблением памяти и cpu самих подов coreDNS, сколько cache miss происходит (как часто приходится DNS обращаться к внешним DNS, если это происходит слишком часто то возможно нужно увеличить количество записей которые coreDNS может хранить у себя в cache), доступность coreDNS
`Ingress Controller` - Следим за подами (что они доступны и работают и потребляют нормальное количество памяти и процессора), метрики контроллеров в формате Prometheus  
`Относящиеся к приложению`:  
    ```text
    Статус деплоймента - Мог ли наш деплоймент последний раз развернуться, Сколько реплик деплоймент находится в состоянии ready
    Состояния подов - Нет ли подов в состоянии CrashLoopBack, количество рестартов за пять минут.
    Метрики ингрессов (не контроллер а объекты кластера kubernetes) - количество запросов на каждый ингресс, как быстро отвечабт бекенды, статус коды ответов бекендов. 
    ```

4. Метрики ннод и ОС  
Использование дисков, памяти, CPU, Network, Остатки свободного места на дисках, Load Average

## SRE
### SLI
Это конкретные метрики в системе которые мы можем выделеть в качестве показателей жизнеспособности системы.  
Например:  
`kubeapi server`  
1. Количество ошибок которые возвращает наш kubeapi server
2. Время за которое в среднем kubeapi server отвечает на запросы

### SLO (Service Level Objectives)
Это конкретные пороговые значения для этих метрик после наступления которых мы считаем что с системой произошла какая-то ошибка.  
Например:  
`kubeapi server`  
1. Работает хорошо если отвечает на запросы быстрее 100мс
2. Работает хорошо если он выдает не более 5 ошибок в течении минуты

### Метрики в Grafana:  
Control Plane, мониторинг kube apiserver
1. `Latency`  
SLI данной метрики
`histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{verb!~"WATCH|CONNECT"}[5m])) by (le) )`  
apiserver_request_duration_seconds_bucket - метрика показывает за какое время выполняются наши запросы в api server.  
0.99 - Это перцентиль, т.е. значением матрики будет число - максимальное время обработки запросов для 99% наших запросов в API Server.  
WATCH|CONNECT - Не учитываются запросы типа WATCH|CONNECT потому что они долгоживущие.

SLO данной метрики:  
`100 мс`
т.е. создаем alert на это число.

2. API Server Errors
Количество ошибок:  
Здесь мы смотрим на любые статус коды у которых ответ либо 400 и далее либо 500 и далее и считаем сколько в среднем у нас таких ошибок за 5 мин.  
SLI данной метрики  
`sum(rate(apiserver_request_total{code=~"^(?:4..)$|^(?:5..)$"}[5m])) by (code)>0`  
SLO метрики  
Несколько единиц, например 5  

Что еще смотреть:
3. Количество запросов разных методов (GET, PUT, WATCH...)  
4. Количество запросов по конкретным объектам в кластере  
5. Latency с которым kubernetes отдает объекты (nodes, pods, namespaces, services. configmap ...)

#### ETCD

`etcd_server_leader_changes_seen_total` - как часто меняется лидер в кластере `Etcd`
`grpc_server_handled_total` - все запросы в Etcd (например можно мониторить ошибки - `grpc_server_handled_total{grpc_code!="OK"}`)  
`grpc_server_handling_seconds_bucket` - на основании этой метрики можно построить Latency запросов в Etcd (см пример с API сервером из видео)  
`etcd_network_peer_round_trip_time_seconds_bucket` - на основании этой метрики можно построить Latency общения инстансов Etcd между собой  
`etcd_disk_wal_fsync_duration_seconds_bucket` - позволяет построить скорости работы с диском (один из самых критичных для Etcd показателей)  

#### Kube API Server

`apiserver_request_count` - позволяет посчитать rps и количество ошибок в запросах к API серверу Кубернетиса  
`apiserver_client_certificate_expiration_seconds_count` - позволяет следить за временем жизни сертификатов в кластере  
`apiserver_request_latencies_bucket` - на основании этой метрики можно построить Latency запросов в kube-api

#### Kubelet (Node)

`kube_node_status_condition` - позволяет проверить статус ноды по множеству различных показателей (например `{condition=«Ready»,status="true"}` позволяет понять что нода находится в статусе `Ready` или `{condition="MemoryPressure",status="true"}` позволяет узнать что на ноде не хватает оперативной памяти)  

#### Полезные алерты для кластера Kubernetes

https://awesome-prometheus-alerts.grep.to/rules#kubernetes  
https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/kubePrometheus-prometheusRule.yaml  
https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/kubeStateMetrics-prometheusRule.yaml  
https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/nodeExporter-prometheusRule.yaml  


## Общие рекомендации по построению production платформы логирования и мониторинга в кластере

1. Разработчик должен иметь возможность самостоятельно ставить свои приложения на мониторинг. Для этого удобно использовать аннотации на сервисах prometheus.io/scrape и prometheus.io/probe.

2. Разработчик должен иметь возможность самостоятельно создавать алерты для своих приложений в кластере. Например можно использовать объект Rules из Prometheus Operator.

Хорошей практикой будет завести набор алертов общего характера (не доступен сервис, поды находятся в CrashLoop и тд) и отправлять их в общий канал мониторинга для дежурных. А алерты разработчиков отправлять в каналы отдельных команд разработки. Для этого очень хорошо подходит фича Alert Manager - роутинг.

3. Алерты должны приходить тем кому они нужны и тем кто будет что то делать с проблемой. Нет смысла слать все алерты дежурному, если он ничего с ними не будет предпринимать. Очень быстро каналы алертов превращаются в бесконечную спам свалку.

4. Каждый пришедший алерт должен обрабатываться. Если по алерту не требуется каких то ручных действий нет смысла отсылать его в канал мониторинга. Возможно достаточно ограничиться электронным письмом или каким то другим каналом передачи с минимальным приоритетом.

5. Нужно различать понятие лога (событие произошедшее в системе) и стактрейса (необработанной ошибки в коде приложения). Логи нужно парсить и по ним составлять необходимые графики и алерты. Стактрейсы нужно собирать в специализированные системы (например Sentry) и работать с ними отдельно.

6. Grafana позволяет на одном графике сочетать данные из нескольких источников. Например данные мониторинга и системы логирования. Таким образом можно связывать например графики ошибок в запросах из мониторинга и сообщения логов, которые эту ошибку описывают.

7. Не имеет смысла собирать все возможные метрики и все возможные сообщения логов в максимальном уровне логирования. Эти данные чаще всего не используются, но при этом очень быстро приводят к разрастанию систем мониторинга и логирования, что может привести к их неработоспособности. Выделите набор нужных метрик, и оптимальный ровень логирования. Обсуждайте с разработкой целесообразност добавления новых метрик.
