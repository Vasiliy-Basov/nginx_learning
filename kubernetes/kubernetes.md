https://www.youtube.com/watch?v=HpMel0AVu_Y&t=135s
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

Устанавливаем dashboard
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Делаем пользователя для доступа
https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md

Извлекаем Bearer Token for ServiceAccount

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

Делаем Proxy для доступа к api kubernetes через локальный webserver 

```bash
kubectl proxy
```

Переходим на наш dashboard
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Вставляем токен который мы получили

## Создание Pod из Dockerfile

Dockerfile находится здесь /home/baggurd/Hugo/Sites/vasiliy.basov.world


```bash
docker images
docker login
docker push vasiliybasov/resume:1.0
# Публикуем pod из контейнера
kubectl run resume-test-1 --image=vasiliybasov/resume:1.0 --port=80
kubectl get pods
kubectl describe pod resume-test-1
# Зайти внутрь контейнера
kubectl exec -it resume-test-1 -- /bin/sh
# Если несколько контейнеров то нужно явно указать имя контейнера
kubectl exec -it resume-test-1 --container resume-test-1 -- /bin/sh

```

Запускаем второй такой же pod но уже из yaml файла
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/pod_resume

```bash
kubectl apply -f pod-resume.yaml
```
Посмотреть yaml как он выглядит в kubernetes (полный)
```bash
kubectl get pod resume-test-2 -o yaml
```
Смотреть поды в реальном времени
```bash
kubectl get pods --watch
```

Можем сделать portforward с порта контейнера на порт машины с на которой мы запускаем kubectl и посмотреть как работает наше приложение
```bash
kubectl port-forward resume-test-1 11111:80
```
Зайдем и проверим что все работает
http://localhost:11111/

Посмотреть логи
```bash
kubectl logs resume-test-1
```
Так же логи можем посмотреть через dashboard (kubectl proxy)
или зайти внутрь контейнера через dashboard

## Create Pod with Labels
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/pod_resume/pod-resume-with-labels.yaml

```bash
kubectl apply -f pod-resume-with-labels.yaml
# Посмотреть pod с labels
kubectl get pod --show-labels
# или конкретные labels по столбцам
kubectl get pod -L app,environment,run
# Выбрать pods с конкретными метками
kubectl get pod -l app=resume-web
kubectl get pod -l 'app in (resume-web)'
# Выбрать все pods которые не содержат эту метку (не равно)
kubectl get pod -l app!=resume-web
kubectl get pod -l 'app notin (resume-web)'
# Все pods у которых существует метка run
kubectl get pod -l run
# Все pods у которых нет метки run
kubectl get pod -l '!run'
```

Добавить label к существующему pod 
```bash
kubectl label pod resume-test-1 environment=dev
```
или просто изменим манифест добавим туда новые labels и применим

Добавляем метки к нодам например чтобы запускать pods только на определенных нодах.
```bash
kubectl label node gke-k8s-test-k8s-node-pool-d39c0fd9-f75l gpu=true
kubectl get nodes -l gpu=true
```

Делаем манифест чтобы под ставился только на ноды с определенными метками
```bash
kubectl apply -f pod-resume-with-gpu.yaml
```
```yaml
spec:
  # Ставим только на те ноды у которых label gpu=true
  nodeSelector:
    gpu: "true"
```

## Аннотации
Описание для объектов в kubernetes
Не существует selector-ов для аннотаций как для labels

Добавляем аннотацию кто был создателем объекта
```bash
kubectl annotate pod resume-test-2 company-name/creator-email="vasiliy.basov.82@gmail.com"
```

## Replication Controller
Устаревший контроллер, сейчас используют ReplicaSet
Следит чтобы было запущено определенное количество подов
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/8_replication/rc-kuber.yaml

Чтобы вывести pod из области действия Replication Controller просто поменяйте label на этом pod

 <span style="color:red"> ! Если мы изменим шаблон пода (template) внутри манифеста и применим его то ничего не изменится и новые поды не появятся пока мы не удалим старые. <span>

Удаление

```bash
kubectl get rc
kubectl delete rc kuber-rc
```

## ReplicaSet
Аналогично Replication Controller

```yaml
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: kuber-rs-2
spec:
  replicas: 3
  # Будет действовать только на поды которые соответствуют выражению
  selector:
    matchExpressions:
      # Ключ app
      - key: app
        # In (или) (Означает что app должен быть равен или kuber или http-server) (можем использовать NotIn)
        operator: In
        values:
          - kuber
          - http-server
      # Должен существовать label с ключом env и любым значением. Также можем использовать (DoesNotExist)
      - key: env
        operator: Exists
  # Шаблон на основе которого будут создаваться поды
  template:
    metadata:
      # Labels должны совпадать с теми которые указаны в блоке selector
      labels:
        app: kuber
        env: dev
    spec:
      containers:
      - name: resume-test
        image: vasiliybasov/resume:1.0
        ports:
        - containerPort: 80

```

## Deployment
Оркеструет ReplicaSet
т.е. если мы создадим новую версию нашего приложения он создаст новый ReplicaSet который создаст новые реплики pods а старый ReplicaSet будет иметь 0 pods что удалит старые версии приложения.

Выглядит файл аналогично ReplicaSet

/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/9_Deployment
Запускаем приложение

```bash
kubectl apply -f kuber-deployment.yaml --record
```

### Применяем сервис для нашего deployment
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/9_Deployment/kuber-service.yaml

```bash
kubectl apply -f kuber-service.yaml
```
Проверяем что все работает заходим на ip одной из нод с нужным портом

Порт смотрим здесь:
```bash
kubectl get svc
```

```bash
curl -I 10.128.0.5:30718
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuber
  labels:
    app: kuber
spec:
  replicas: 5
  # Замедляем раскрутку, через 10 сек pod будет считаться доступным и принимать трафик
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      # Сколько подов может быть создано дополнительно
      maxSurge: 1
      # Сколько подов будет убиваться
      maxUnavailable: 1
    # Обновление будет происходить постепенно (по умолчанию)
    type: RollingUpdate
  # Будет действовать только на поды с соответствующими labels
  selector:
    matchLabels:
      app: http-server
  # Шаблон на основе которого будут создаваться поды
  template:
    metadata:
      # Labels должны совпадать с теми которые указаны в блоке selector
      labels:
        app: http-server
    spec:
      containers:
      - name: resume-test
        image: vasiliybasov/resume:1.0
        ports:
        - containerPort: 80
```

<span style="color:red"> ! Чтобы заставить изменять наше приложение секция template должна быть изменена <span>

Кроме RollingUpdate есть еще стратегия Recreate

### Recreate
Сначала удаляются все поды и только после этого создаются новые (будет Downtime) Приложение будет не доступно
```yaml
...
  strategy:
    type: Recreate
...
```

Если указывали флаг --record можем посмотреть историю deployment и его ревизии

```bash
kubectl rollout history deployment kuber
```

Если хотим откатится к предыдущей версии то пишем
```bash
kubectl rollout undo deployment kuber
```
Если хотим откатится к конкретной ревизии

```bash
kubectl rollout undo deployment kuber --to-revision=1
```

Deployment откатывается к нужным ревизиям через старые ReplicaSet которые он сохраняет, поэтому не стоит их удалять.

Если хотим поменять image у какого-то deployment:

```bash
kubectl set image deployment.apps/short-app-deployment short-app=antonlarichev/short-app:latest
``` 

Если хотим заново выкатить наш deployment в случае например если контейнер изменился а тег не изменился и нам нужно заново стянуть контейнер не меняя при этом конфигурацию deployment.
Должна быть опция  

```yaml
  imagePullPolicy: Always  
```

В этом случае невозможно откатиться на предыдущую версию, поэтому не рекомендуется так делать  

```bash
kubectl rollout restart deployment short-app-deployment -n test
```

## Service
Что вроде коммутатора
![](/pics/service.png)
![](/pics/service-sch.png)

Kube-proxy - проксирует запросы от кластера до определенного сервиса

### ClusterIp
Ip назначается внутри кластера только для доступа к подам изнутри

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kuber-service
spec:
  # На основании этого селектора происходит доступ к подам где прописан такой же label
  selector:
    app: http-server
  ports:
    - protocol: TCP
      # Порт сервиса
      port: 80
      # Порт контейнера (вместо номера порта также можем использовать имя)
      targetPort: 80
  # Default Type. Ip назначается в пределах кластера. Только внутренний.
  type: ClusterIP
```

Сервис лучше создавать до того как мы создали deployment.
Что бы внутрь pod попали переменные окружения от сервиса и  чтобы например вместо ip адресов вводить переменные окружения.

Чтобы посмотреть переменные окружения заходим внутрь пода и вводим 
```bash
env
```
Мы можем обратиться к нашему поду через dns 

```bash
# Внутри пода смотрим dns
cat /etc/resolv.conf
# Обращаемся к нашему сервису по dns
# kuber-service - имя нашего сервиса
# default - это namespace
curl http://kuber-service.default.svc.cluster.local
# Если находимся в том же namespace то можем обращаться и напрямую по имени
curl http://kuber-service
```

#### Endpoints
Конечные точки (ip адреса подов) для каждого из наших сервисов
Список ip адресов наших подов

Имя сервиса и имя endpoint должны совпадать
```bash
$ kubectl get endpoints
NAME            ENDPOINTS                                   AGE
kuber-service   10.72.1.25:80,10.72.2.17:80,10.72.2.18:80   20h
kubernetes      10.128.0.3:443                              17d
$ kubectl get svc
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kuber-service   NodePort    10.75.253.16   <none>        80:30718/TCP   20h
kubernetes      ClusterIP   10.75.240.1    <none>        443/TCP        17d
```

Можно указать endpoint-ы вручную тогда сервис может быть без селектора
```yaml
apiVersion: v1
kind: Service
metadata:
  name: endpoints-service
spec:
  ports:
  - port: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: endpoints-service
subsets:
  - addresses:
    - ip: 10.72.1.25
    - ip: 10.72.2.17
    ports:
    - port: 80
```
#### ClusterIp без iP адреса подключение ко всем подам одновременно

Если нам нужно подключиться ко всем подам одновременно.
Например приложению нужно получить ip адреса всех подов для подключения.
Для этого создаем сервис без назначения ему ip адреса

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kuber-headless-service
spec:
  clusterIP: None
  # На основании этого селектора происходит доступ к подам где прописан такой же label
  selector:
    app: http-server
  ports:
    - name: http
      protocol: TCP
      # Порт сервиса
      port: 80
      # Порт контейнера (вместо номера порта также можем использовать имя)
      # Тогда имя должно быть задано в секции spec.ports в Deployment
      targetPort: http
  # Default Type. Ip назначается в пределах кластера. Только внутренний.
  type: ClusterIP
```

```bash
baggurd@ubuntu22:~/Dropbox/Projects/nginx_learning/kubernetes/10_service$ kubectl apply -f kuber-headless-service.yaml
service/kuber-headless-service created
baggurd@ubuntu22:~/Dropbox/Projects/nginx_learning/kubernetes/10_service$ kubectl get svc
NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kuber-headless-service   ClusterIP   None           <none>        80/TCP         12s
kuber-service            NodePort    10.75.253.16   <none>        80:30718/TCP   21h
kubernetes               ClusterIP   10.75.240.1    <none>        443/TCP        17d
```

Мы не сможем подключиться к подам через clusterIP
```bash
curl http://kuber-headless-service.default.svc.cluster.local
```

Но мы можем подключаться ко всем подам сразу
nslookup выдает ip всех подов:
```bash
/usr/share/nginx/html # nslookup kuber-headless-service.default.svc.cluster.local
Server:         10.75.240.10
Address:        10.75.240.10:53

Name:   kuber-headless-service.default.svc.cluster.local
Address: 10.72.1.25
Name:   kuber-headless-service.default.svc.cluster.local
Address: 10.72.2.17
Name:   kuber-headless-service.default.svc.cluster.local
Address: 10.72.2.18
```

### Service ExternalName
Если мы хотим обращаться к какому то внешнему сервису например к базе данных которая находится во вне по внутреннему dns имени сервиса

По сути это аналог cname в dns

Если мы захотим поменять эту базу данных мы просто меняем имя базы в этом сервисе без изменения нашего приложения которое на эту базу ссылается и оно буде работать уже с новой базой

```yaml
apiVersion: v1
kind: Service
metadata:
  # Имя сервиса для того чтобы приложения обращались к нему чтобы попасть на внешний ресурс
  name: external-service
spec:
  type: ExternalName
  # Внешнее имя куда идет перенаправление при обращении к имени сервиса
  externalName: example.com
```
Могут быть проблемы если мы обращаемся по таким протоколам как http и https

### NodePort

![](/pics/nodeport.png)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: short-app-port
spec:
  type: NodePort
  ports:
  # Порт для других подов которые хотят получить доступ к этому поду
  - port: 3000
    # Порт внутри контейнера куда мы прокидываем NodePort (containerPort)
    targetPort: 80
    # Порт который нужно будет вводить клиенту
    NodePort: 31200 # port-range: 30000-32767
  # Привязываем сервис к подам у которых есть эти labels:
  selector: 
    components: frontend
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kuber-service-nodeport
spec:
  # Трафик будет поступать всегда на одну ноду (не под) (на первую к которой подключится)
  externalTrafficPolicy: Local
  # Эта настройка делает то что клиент после подключения к определенному поду после этого трафик всегда будет направляться только к этому поду.
  # sessionAffinity: ClientIP
  # Это поле идентично тому которое есть в Deployment чтобы взаимодействовать с теми же pods
  selector:
    app: http-server
  ports:
    - protocol: TCP
      # Порт по которому будет отвечать сам сервис
      port: 80
      # Порт на контейнерах pods (containerPort) к которым подключаемся.
      targetPort: 80
      nodePort: 30080 # port-range: 30000-32767
  type: NodePort
```

curl http://kuber-service-nodeport

Можем зайти на наш сервис из вне по любому ip адресу external IP любой нашей ноды

http://34.121.113.29:30080/
Нужно открыть порт в Firewall

### LoadBalancer
Работает только на cloud providers (Amazon, GCP, Azure ...)
Это улучшенная версия NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kuber-service-lb
spec:
  # Трафик будет поступать всегда на одну ноду (не под) (на первую к которой подключится)
  externalTrafficPolicy: Local
  selector:
    app: http-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer

```
```bash
kubectl get svc
```
Проверяем что все работает
http://34.171.9.146/

Если есть ноды без подов то запрос может зависнуть

### Ingress
Работает на 7 уровне OSI
Чтобы ingress работал в кластере должен быть запущен контроллер ingress
есть много разных котроллеров, можно посмотреть все на официальном сайте.

![](/pics/architecture.png)

```bash
kubectl get ingress -A
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  # аннотации это конфигурация nginx
  # annotations:
    # rewrite правило, перенаправляет все запросы на корневой путь /
    # nginx.ingress.kubernetes.io/rewrite-target: /  
    # Автоматически добавляет базовый URL к ссылкам в ответах от приложения
    # nginx.ingress.kubernetes.io/add-base-url: "true"
spec:
  rules:
  # Все запросы которые приходят на этот хост будут перенаправляться на этот сервис
  - host: vasiliy.basov.world
    http:
      paths:
        # Тип Prefix означает что все запросы которые начинаются на vasiliy.basov.world/... будут перенаправляться на наш сервис вместо ... может быть все что угодно
        - pathType: Prefix
          path: /
          backend:
            # Указываем имя сервиса и порт сервиса куда будет посылаться трафик с запросов которые будут приходить на хост vasiliy.basov.world
            service:
              name: kuber-service
              port: 
                number: 80

        # Тип Exact означает что только запросы vasiliy.basov.world/v2 будут обрабатываться
        # - pathType: Exact
        #   path: /v2
        #   backend:
        #     service:
        #       name: kuber-service
        #       port: 
        #         number: 80
  # Если мы поставили nginx ingress controller то мы должны указать эту настройку иначе не выдастся ip адрес
  ingressClassName: nginx

```

## Liveness, Readiness, Startup Probes
### Liveness Probe
Перезапуск контейнера в случае если проверка не прошла
Есть 3 типа проверок
- http get
- exec
- TCP

1) Проверка типа exec
```yaml
    spec:
      container:
        ...
        ...
        livenessProbe:
          exec:
            command:
            # Проверяем командой cat существует ли это файл (healthy) или нет. Если код будет 0 то проверка выполнена.
            - cat
            - /tmp/healthy
          # Количество секунд от старта контейнера до начала Liveness пробы
          initialDelaySeconds: 5 # Defaults to 0 seconds. Minimum value is 0.
          # Длительность времени между проведением prob
          periodSeconds: 5 # Default to 10 seconds. Minimum value is 1.
          # Сколько ожидать probe
          timeoutSeconds: 1 # Defaults to 1 second. Minimum value is 1.
          # Минимально количество проверок чтобы probe была успешной после неудачной
          successThreshold: 1 # Defaults to 1. Must be 1 for liveness and startup Probes. Minimum value is 1.
          # количество неудачных проверок чтобы считать контейнер умершим
          failureThreshold: 3 # Defaults to 3. Minimum value is 1.
```

2) Проверка типа TCP

```yaml
        # Проверка подключения к TCP порту контейнера
        livenessProbe:
          tcpSocket:
            port: 8000
          initialDelaySeconds: 15 # Defaults to 0 seconds. Minimum value is 0.
          periodSeconds: 10 # Default to 10 seconds. Minimum value is 1.
          timeoutSeconds: 1 # Defaults to 1 second. Minimum value is 1.
          successThreshold: 1 # Defaults to 1. Must be 1 for liveness and startup Probes. Minimum value is 1.
          failureThreshold: 3 # Defaults to 3. Minimum value is 1.
```

3) Проверка типа http get

Проверка будет успешной если отклик будет без ошибки (200 отклик)
В случае 400 500 ошибок pod будет считаться failure и перезапуститься
```yaml
        # Проверка того что контейнер отвечает если не отвечает то перезапускает его
        livenessProbe:
          httpGet:
            # Путь по которому происходит проверка
            path: /
            port: 80
          initialDelaySeconds: 5
          # Запросы каждые 5 секунд
          periodSeconds: 5
```

Проверка с использованием httpHeader.  
т.е. если например в зависимости то того какое имя мы будем вводить в браузере nginx будет посылать нас на разные приложения или страницы. Мы это также можем учитывать в наших probes

Проверяем curl 
```bash
curl -v -H "Host: vasiliy.basov.world" http://34.133.145.193
```
```yaml
        livenessProbe:
          httpGet:
            # Путь по которому происходит проверка c учетом httpHeaders
            path: /
            httpHeaders:
            - name: Host
              value: vasiliy.basov.world
            port: 80
          initialDelaySeconds: 5
          # Запросы каждые 5 секунд
          periodSeconds: 5

```


### Readiness Probe

yaml файл идентичен Liveness Probe, но вместо перезапуска контейнера будет блокироваться трафик с сервиса на этот контейнер

```yaml
        # Проверка того что контейнер отвечает если не отвечает то перестает слать на него трафик
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Startup Probe
Нужна если у нас старое приложение и нужно время для инициализации

Т.е. сначала будет работать startup probe и как только приложение запустится она передаст свой функционал liveness probe

Допустим мы даем 310 секунд на запуск приложения, настройка будет такая:

```yaml
        startupProbe:
          exec:
            command:
            - cat
            - /server-test.py
          initialDelaySeconds: 10
          failureThreshold: 30 # 30 * 10 = 300 + 10 = 310 sec
          periodSeconds: 10
```

## Переопределение аргументов CMD и ENTRYPOINT Docker инструкций, используя Kubernetes

CMD используется только если нужно определить аргументы по умолчанию пример ниже:

Пример Dockerfile
```Dockerfile
FROM python:3.8.5
COPY server.py /server.py
COPY server-default.py /server-default.py
# Правильная форма объявления entrypoint инструкций (EXEC) без использования SHELL. 
ENTRYPOINT ["python3","-u", "server.py"]
CMD ["1","5","text"]
```
Это аналогично команде
```bash
python3 -u server.py 1 5 text
```

Kubernetes позволяет переопределять не только CMD но и ENTRYPOINT

Переопределение CMD аргументов:
```yaml
    spec:
      containers:
      - name: kuber-app
        image: bakavets/kuber:v1.0-args
        args: 
        - "3"
        - "2"
        - text-temp
        ports:
        - containerPort: 8000
```

Переопределение ENTRYPOINT аргументов:
```yaml
    spec:
      containers:
      - name: kuber-app
        image: bakavets/kuber:v1.0-args
        # Переопределение ENTRYPOINT аргументов
        command: ["python3","-u", "server.py"]
        # Переопределение CMD аргументов, числа обязательно брать в кавычки
        args: 
        - "3"
        - "2"
        - text-temp
        ports:
        - containerPort: 8000
```

## Настройка HTTPS для web-app в Kubernetes. NGINX Ingress и cert manager. Let's Encrypt

https://www.youtube.com/watch?v=8ULmDxTzAVQ&t=1012s

1) Покупаем домен
2) Добавляем в `cloud DNS - DNS Zone`
3) Ставим `Kubernetes` и добавляем в `dns zone` запись для нашего `ingress`  
DNS name *.basov.world.  
Type A  
TTL(seconds) 300  
34.133.145.193
4) Ставим `ingress controller`
5) Ставим `ingress.yaml` +  `deployment` + `service`
6) Ставим `Cert Manager`
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.4 --set installCRDs=true --set ingressShim.defaultIssuerName=letsencrypt-prod --set ingressShim.defaultIssuerKind=ClusterIssuer --set ingressShim.defaultIssuerGroup=cert-manager.io
```
```bash
# Эти настройки нужны чтобы при указании аннотации kubernetes.io/tls-acme: "true" cert manager создавал сертификат для всех таких ingress:
--set ingressShim.defaultIssuerName=letsencrypt-prod --set ingressShim.defaultIssuerKind=ClusterIssuer --set ingressShim.defaultIssuerGroup=cert-manager.io
```

Чтобы это сработало также необходимо создать `default cluster issuer letsencrypt-prod`:
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/ClusterIssuer/letsencrypt-prod.yaml :

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: vasiliy.basov.82@gmail.com
    # Staging не выпускает доверенные сертификаты но он нужен чтобы удостовериться что 
    # весь процесс работает как надо перед конфигурацией Production 
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the ACME account's private key.
      name: letsencrypt-prod
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```
И применить его 
```bash
kubectl apply -f letsencrypt-prod.yaml
```
7) Создаем объект Issuer или ClusterIssuer (Custom объект kubernetes, по умолчанию его нет), Issuer действует в пределах namespace. ClusterIssuer во всем кластере.
https://cert-manager.io/docs/configuration/acme/

Когда мы создадим новый ACME Issuer, Cert manager сгенерирует private key который будет использоваться чтобы идентифицировать нас в ACME server (Let's Encrypt)

https://cert-manager.io/docs/tutorials/acme/nginx-ingress/

/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/16_https/staging_ClusterIssuer.yaml
```bash
k apply -f staging_ClusterIssuer.yaml
```
Посмотреть что мы создали
```bash
k get clusterissuers.cert-manager.io
```

Проверка сертификатов
```bash
kubectl get certificate -A
kubectl describe certificate -n monitoring prometheus-server-tls
kubectl get certificaterequest -A
kubectl describe certificaterequest prometheus-server-tls-l54gx -n monitoring
kubectl get clusterissuer
```

## Lens
Регистрируемся скачиваем устанавливаем:
https://app.k8slens.dev/subscribe-personal

```bash
sudo dpkg -i Lens-2023.9.290703-latest.amd64.deb
```

## Volumes

Volume - Выделенная область внутри pod  
Persistent Volume - Отдельный объект вне pod  
Persistent Volume Claim - Запрос на выделение Volume для pod  

### EmptyDir

```yaml
# EmptyDir удаляется при удалении пода.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuber
  labels:
    app: kuber
spec:
  replicas: 1
  selector:
    matchLabels:
      app: http-server
  template:
    metadata:
      labels:
        app: http-server
    spec:
      containers:
      - name: kuber-app-1
        image: bakavets/kuber
        ports:
        - containerPort: 8000
        volumeMounts:
        # Путь внутри контейнера
        - mountPath: /cache-1
          name: cache-volume
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        # Путь внутри контейнера (Если внутри контейнера в эта папка существует то файлы из нее заменяться на файлы cache-volume)
        - mountPath: /usr/share/nginx/html/data
        # - mountPath: /cache-2
          name: cache-volume
          # Если мы создадим файлы в /usr/share/nginx/html/data то в /cache-1 другого контейнера файлы появятся в /cache-1/data так работает subPath
          subPath: data
      # Указываем тип и имя volume
      volumes:
      - name: cache-volume
        # Выделить подам дисковое пространство на ноде где запускаются поды, 
        # если мы подключим этот диск двум подам то данные в двух подах будут одинаковые
        # На ноде emptyDir хранится по пути /var/lib/kubelet/pods/<uid_пода>/volumes/kubernetes.io~empty-dir/<имя_volume>/
        emptyDir: {}
```

```yaml
# Данные которые генерируются в контейнере debian будут попадать в контейнер nginx в режиме readonly, данные хранятся в оперативной памяти.
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
spec:
  restartPolicy: Never
  containers:
    - name: nginx-container
      image: nginx
      volumeMounts:
      - name: shared-data
      # Путь внутри контейнера
        mountPath: /usr/share/nginx/html
        # container сможет только читать конфиг
        readOnly: true
    - name: debian-container
      image: debian
      volumeMounts:
      - name: shared-data
        # Путь внутри контейнера
        mountPath: /pod-data
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo Hello from the debian container date: $(date)> /pod-data/index.html; sleep 1; done"]
  volumes:
  - name: shared-data
    emptyDir: # {}
      # Монтирование tmpfs в оперативную память вместо диска
       medium: Memory
```

### hostPath

Не рекомендуется использовать из за проблем с безопасностью  
Данные сохраняются на host-е если pod удаляется данные сохраняются.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: bakavets/kuber
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      # Это путь к директории на host-е
      path: /data
      # this field is optional. поле, которое указывает, что по пути /data на узле 
      # должна быть директория. Если директории не существует, она не будет автоматически создана, и под не запустится
      type: Directory
```

### PersistentVolume
Часть хранилища в кластере которое было подготовлено администратором кластера либо динамически предоставлено storage class

```yaml
# https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/
# Это объект кластерного уровня и не имеет namespace
apiVersion: v1
kind: PersistentVolume
metadata:
  name: aws-pv-kuber
  labels:
    type: aws-pv-kuber
spec:
  capacity:
    # Объем хранилища
    storage: 3Gi
  accessModes: # https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes
    # Может быть смонтирован для чтения и записи только одной ноды
    - ReadWriteOnce
  # Что произойдет с хранилищем после того как оно будет использовано и освобождено и будет удален pod и PersistentVolumeClaim  
  # Recycle - означает что volume будет очищен и готов к повторному использованию
  persistentVolumeReclaimPolicy: Retain # https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/#PersistentVolumeSpec # https://kubernetes.io/docs/concepts/storage/persistent-volumes/#recycle
  storageClassName: "" # Empty value means that this volume does not belong to any StorageClass. https://kubernetes.io/docs/concepts/storage/persistent-volumes/#class-1
  # Плагин который вшит в kubernetes, поддерживает только ReadWriteOnce. Рекомендуется использовать CSI драйвера для нужного провайдера а не встроенные плагины.
  # Этот PersistentVolume должен быть создан заранее в AWS  
  awsElasticBlockStore:
    volumeID: "vol-02a71cfd076eac916"
    fsType: ext4
```

### PersistentVolumeClaim
Заявка на определенное хранилище

```yaml
# https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/
# Заявка на хранилище PersistentVolume
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: aws-pvc-kuber
spec:
  storageClassName: "" # Empty string must be explicitly set otherwise default StorageClass will be set
  # Эти параметры должны полностью удовлетворять созданному нами PV что бы заявка была выполнена
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

### StorageClass

Нужен чтобы создавать динамические PV

Создаем StorageClass

```yaml
# https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/storage-class-v1/
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: custom-gp2
# Это поставщик нашего плагина или csi Driver Name
provisioner: kubernetes.io/aws-ebs # https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner
# Параметры диска относящиеся к Amazon
parameters:
  type: gp2
# Оставлять или удалять (Delete) PV после удаления PVC
reclaimPolicy: Retain # https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy
# Возможность расширять диск
allowVolumeExpansion: true
```

Создаем PVC

В Этом случае PV будет создан динамически с помощью SC  

```yaml
# https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: aws-pvc-kuber-1
spec:
  # Указываем наш StorageClass если не укажем то выберется Default SC если хотим чтобы StorageClass вообще не выбирался то указываем пустую строчку "".
  storageClassName: "custom-gp2"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi
```

Создаем Deployment для нашего PVC

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuber-1
  labels:
    app: kuber
spec:
  replicas: 1
  selector:
    matchLabels:
      app: http-server
  template:
    metadata:
      labels:
        app: http-server
    spec:
      containers:
      - name: kuber-app
        image: bakavets/kuber
        ports:
        - containerPort: 8000
        volumeMounts:
        - mountPath: /cache
          name: cache-volume
      volumes:
      - name: cache-volume
        persistentVolumeClaim:
          claimName: aws-pvc-kuber-1
```

## Secrets

### Секреты из файла

Создаем два файла

```bash
echo -n 'admin' > ./username.txt
echo -n 'superpass12345&*' > ./password.txt
```

Создаем секрет типа generic с именем db-user-pass-from-file
```bash
# Создаем секрет типа generic с именем db-user-pass-from-file используя файлы
kubectl create secret generic db-user-pass-from-file \
  --from-file=./username.txt \
  --from-file=./password.txt
```

```bash
# Посмотреть yaml с секретом, kubernetes хранит секреты в BASE64 формате
kubectl get secret db-user-pass-from-file -o yaml
```
```bash
# Декодировать секрет из BASE64
echo "c3VwZXJwYXNzMTIzNDUmKg==" | base64 -d
```

### Секреты из literal 
literal - представляют собой константы или значения переменных(но не сами переменные)

```bash
# Здесь ключ секрета username а значение секрета devuser:
kubectl create secret generic db-user-pass-from-literal \
  --from-literal=username=devuser \
  --from-literal=password='P!S?*r$zDsY'
```

### Вывод значений наших секретов

```bash
kubectl get secret db-user-pass-from-file -o jsonpath='{.data}'
```

```bash
kubectl get secret db-user-pass-from-literal -o jsonpath='{.data.password}' | base64 --decode
```
### Секреты из манифеста yaml

Секрет в BASE64
```yaml
# echo -n 'adminuser' | base64
# echo -n 'Rt2GG#(ERgf09' | base64
apiVersion: v1
kind: Secret
metadata:
  name: secret-data
type: Opaque
data:
  username: YWRtaW51c2Vy
  password: UnQyR0cjKEVSZ2YwOQ==
# echo -n 'YWRtaW51c2Vy' | base64 --decode
# echo -n 'UnQyR0cjKEVSZ2YwOQ==' | base64 --decode
```
```bash
k apply -f secret-data.yaml
```

Секрет в обычной кодировке stringData
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-stringdata
type: Opaque
stringData:
  username: adminuser
  password: Rt2GG#(ERgf09
```
```bash
k apply -f secret-stringData.yaml
```

## Использование секретов внутри наших контейнеров
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/27_secrets/example-1

```yaml
    spec:
      containers:
      - name: resume-secret-test
        image: vasiliybasov/resume:1.0
        ports:
        - name: http
          containerPort: 80
        # Получаем переменные для контейнера из секрета secret-data
        # Дополнительные переменные окружения будут добавлены в контейнер и названия этих переменных будут соответствовать ключам секрета.
        envFrom:
        - secretRef:
            name: secret-data
```

Если мы хоти поменять имена переменных а взять только значения секретов:

```yaml
        # Получаем переменные для контейнера из секрета secret-stringdata
        # Переменной SECRET_USERNAME мы присваиваем значение указанное для ключа username в секрете
        env:
          - name: SECRET_USERNAME
            valueFrom:
              secretKeyRef:
                name: secret-stringdata
                key: username
          - name: SECRET_PASSWORD
            valueFrom:
              secretKeyRef:
                name: secret-stringdata
                key: password
```

## Использование секретов внутри наших контейнеров используя volume а не env (более безопасный способ)
/home/baggurd/Dropbox/Projects/nginx_learning/kubernetes/27_secrets/example-2

Секреты попадают внутрь контейнера уже декодированном виде

```yaml
        # Вместо переменных окружения env мы монтируем в файлы (в нашем случае файлы password и username) наши секреты внутрь нашего контейнера по пути /etc/secrets.
        # На самом деле password и username будут там в качестве линков сами файлы находятся внутри каталога со временем создания.
        volumeMounts:
        - name: secrets
          mountPath: "/etc/secrets"
      volumes:
      - name: secrets
        secret:
          secretName: secret-data
          # права на файлы которые будут создаваться
          defaultMode: 0400
```
Монтируем конкретный секрет по конкретному пути /etc/secrets/my-group/my-username

```yaml
        # Монтируем в /etc/secrets только кокретное значение username из секрета secret-data создаем внутри контейнера файл по пути my-group/my-username
        volumeMounts:
        - name: secrets
          mountPath: "/etc/secrets"
      volumes:
      - name: secrets
        secret:
          secretName: secret-data
          items:
          - key: username
            path: my-group/my-username
```

Заходим внутрь контейнера и запускаем 
```bash
df -h
```
чтобы посмотреть куда монтируется папка `/etc/secrets`  
Папка монтируется в `tmpfs` - `Temp file Storage` это временное файловое хранилище предназначенное для монтирования файловой системы. Размещается оно в `оперативной памяти` вместо `физического диска`.  
Это более безопасно чем писать на диск, и более безопасно чем писать в переменные окружения `env` которые могут попасть в логи или сторонние приложения.

## Типы секретов
https://kubernetes.io/docs/concepts/configuration/secret/

### Opaque
Секреты которые мы создавали с произвольными пользовательскими данными

Мы можем ограничится только этим типом секрета и создавать все секреты в нем но для удобства существуют другие типы секретов.

Так же во всех типах секретов мы можем создавать дополнительные поля с данными если нам это необходимо.

### kubernetes.io/service-account-token
Используется для хранения токена идентифицирующего service account

### kubernetes.io/dockercfg и kubernetes.io/dockerconfigjson

Используются чтобы хранить credentials для доступа в Private Container Image Registry (Приватные репозитории из приватных Docker Registry)

dockercfg - более устаревший формат

Чтобы позволить kubelet сделать pull docker контейнера из приватного репозитория необходимо создать секрет

Сначала мы должны создать Access Token для доступа в приватный репозиторий
```
Docker Hub - Account Settings - Security - New Access Token
```
Вставляем токен и создаем секрет:

```bash
kubectl create secret docker-registry secret-docker-registry \
  --docker-email=vasiliy.basov.82@gmail.com \
  --docker-username=vasiliybasov \
  --docker-password=Сюда_вставляем_наш_токен \
  --docker-server=https://index.docker.io/v1/
```
Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

Чтобы использовать секрет прописываем следующие в deployment

```yaml
    spec:
      # Секрет для pull docker image from private registry
      imagePullSecrets:
      - name: secret-docker-registry
      containers:
      - name: kuber-app
        image: bakavets/kuber-private
        ports:
        - containerPort: 8000
```

### kubernetes.io/basic-auth
Хранит учетные данные для базовой аутентификации
Должен содержать один из следующих ключей
username или password или оба

```yaml
# Ref: https://kubernetes.io/docs/concepts/configuration/secret/#basic-authentication-secret
apiVersion: v1
kind: Secret
metadata:
  name: secret-basic-auth
type: kubernetes.io/basic-auth
stringData:
  username: admin      # required field for kubernetes.io/basic-auth
  password: t0p-Secret # required field for kubernetes.io/basic-auth
```

### kubernetes.io/ssh-auth
Для аутентификации при использовании ssh
Должен содержать ключ ssh-auth
```yaml
# Ref: https://kubernetes.io/docs/concepts/configuration/secret/#ssh-authentication-secrets
apiVersion: v1
kind: Secret
metadata:
  name: secret-ssh-auth
type: kubernetes.io/ssh-auth
stringData:
  # the data is abbreviated in this example
  ssh-privatekey: |
          Наш_ssh_auth_ключ
```

### kubernetes.io/tls
Предназначен для хранения сертификата и связанного с ним ключа который обычно используется для tls. Оба ключа должны быть указаны.

```yaml
# Ref: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
apiVersion: v1
kind: Secret
metadata:
  name: secret-tls
type: kubernetes.io/tls
stringData:
  # the data is abbreviated in this example
  tls.crt: |
        MIIC2DCCAcCgAwIBAgIBATANBgkqh
  tls.key: |
        MIIEpgIBAAKCAQEA7yn3bRHQ5FHMQ
```

### bootstrap.kubernetes.io/token
Предназначен для токенов используемых в процессе начальной загрузки ноды. 
