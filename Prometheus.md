# Prometheus

## Install node_exporter

Инсталлируем с помощью ansible
../Projects/nginx_learning/ansible

```bash
ansible-playbook node_exporter.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```

В gcp нужно открыть порт 9100 делаем это через terraform
../Projects/nginx_learning/terraform

Проверка что все работает:
http://nginx.basov.world:9100/metrics

## Ключи запуска Node Exporter
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

## Install  blackbox_exporter
Инсталлируем с помощью ansible
../Projects/nginx_learning/ansible

```bash
ansible-playbook blackbox_exporter.yaml --private-key /home/baggurd/.ssh/appuser_ed25519
```

## ICMP протокол
добавили в blackbox.yml
```yaml
  icmp_slurm:
    prober: icmp
    timeout: 2s
    icmp:
      preferred_ip_protocol: "ip4"
```

Проверяем что prometheus.io доступен с помощью нашего модуля icmp_slurm
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

## Default port allocations
Занятые порты которые лучше не использовать если пишем свой экспортер
https://github.com/prometheus/prometheus/wiki/Default-port-allocations
