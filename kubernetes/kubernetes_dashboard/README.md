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
