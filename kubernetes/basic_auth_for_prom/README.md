Создаем пароль в файл auth (здесь пароль admin)
```bash
htpasswd -c auth admin
```
Создаем секрет из файла auth
```bash
kubectl create secret generic basic-auth --from-file auth -n monitoring
```

Прописываем аннотации для ingress в values.yaml
```yaml
    annotations:
      # type of authentication
      nginx.ingress.kubernetes.io/auth-type: basic
      # name of the secret that contains the user/password definitions
      nginx.ingress.kubernetes.io/auth-secret: basic-auth
      # message to display with an appropriate context why the authentication is required
      nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

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
          - targets:
            - prometheus.k8s.basov.world:80
        # Прописываем аутентификацию если настроена на основном сервере    
        basic_auth:
          username: 'admin'
          password: 'admin'
```
