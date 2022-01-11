---
title: Накручивание CDN + IAP на GCP GKE
date: 2022-01-11
tags: gcp gke iap cdn
---

Праздники закончились, феерверки взорваны, салаты съедены, подарки получены, дети пошли снова в школу, а родитель продолжает колупать необъятные просторы GCP и Kubernetes. Ворвусь тигром в год новый с [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/concepts) ^_^

Практически любое современное веб приложение обслуживает клиентов **статическим** и **динамическим** контентом. Если приложение развёрнуто в Kubernetes, то вероятно приложение будет опубликовано через `Service`, а входной точкой будет `Ingress` направляющий в него запросы.

![Kubernetes 101]({{ "assets/kubernetes-101.svg" | absolute_url }})

Давайте посмотрим на эволюцию конфигурации `Ingress` и `Service` ресурсов развёрнутых в GKE в процессе изменения требований к приложению, которые мне пришлось удовлетворить за прошлый год.

### Один за всех

Самым простым случаем будет отдача статики и динамики одним и тем же сервисом без каких-либо свистелок и перделок, как это показано на рисунке выше. С этим рецептом по-любому сталкивается каждый уважающий себя хеллоуворлдщик в мире кубера. Для развёртывания нам понадобятся манифесты ресурсов (упрощённо):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hane
  labels:
    app.kubernetes.io/name: hane
spec:
  template:
...
```
```yaml
apiVersion: v1
kind: Service
metadata:
  name: hane
  labels:
    app.kubernetes.io/name: hane
annotations:
  # Enable container-native load-balancing,
  # indicating that a NEG should be created to mirror the pod IPs within the service
  cloud.google.com/neg: '{"ingress":true}'
spec:
  selector:
    app.kubernetes.io/name: hane
...
```
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hane
spec:
  rules:
    - host: hane.jp
      http:
        paths:
          - backend:
              service:
                name: hane
                port:
                  number: 80
            path: /*
            pathType: ImplementationSpecific
...
```

Всё по классике за исключением может того, что для GKE `Ingress` ресурсом будет внешний Google Cloud HTTP Load Balancer любезно запровижионенный [ingress-gce](https://github.com/kubernetes/ingress-gce) контроллером. Расчехление балансировщика займёт от [7](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#limitations) до [23](https://issuetracker.google.com/issues/171572578) минут в зависимости от кол-ва уже имеющихся `Ingress`'ов на борту контейнеровоза.

### Добавляем кеш (CDN)

Далее мы хотим раздавать статику по пути `/static/*` через [Google Cloud CDN](https://cloud.google.com/cdn/docs/overview). В этом сервисе определено множество правил, по которым контент [кешируется](https://cloud.google.com/cdn/docs/caching#cacheability) или [нет](https://cloud.google.com/cdn/docs/caching#non-cacheable_content). Можно было бы включить CDN для `Service` и подтюнить приложение таким образом, чтобы ответы удовлетворяли вышеупомянутым требованиям. Однако, не всегда есть доступ к приложению или время менять его кеширующую часть. Поэтому давайте попробуем найти другой способ, но сначала немного про ручки предоставленные GKE. В GKE множество фич связанных с [`Ingress`](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) [кофигурируется](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#configuring_ingress_features) с помощью аннотаций и `FrontendConfig`/`BackendConfig` CRD. В частности настройки [CDN](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#cloud_cdn) для раздачи статического контента и [IAP](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#iap) для аутентифицированно доступа к динамическому контенту (рассмотрим далее) определяются в соответствующих `BackendConfig` ресурсах связанных сервисов.

Альтернативным решением может быть разделение сервиса на 2 отедльных сервиса – один для статики, другой для динамики.

![GKE Service Split CDN]({{ "assets/gke-service-split-cdn.svg" | absolute_url }})

Вот так может выглядеть манифест для включения CDN в рамках сервиса:

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: hane-static
spec:
  cdn:
    enabled: true
    cachePolicy:
      includeHost: true
      includeProtocol: true
      includeQueryString: false
```

и его привязка к новому `Service`:

```yaml
apiVersion: v1
kind: Service
  metadata:
    name: hane-static
    labels:
      app.kubernetes.io/name: hane-static
  annotations:
    cloud.google.com/neg: '{"ingress":true}'
    cloud.google.com/backend-config: '{"ports": {"80":"hane-static"}}'
  spec:
    selector:
      app.kubernetes.io/name: hane
...
```

URL карта `Ingress` ресурса поменяется соответственно:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hane
spec:
  rules:
    - host: hane.jp
      http:
        paths:
          - backend:
              service:
                name: hane-static
                port:
                  number: 80
            path: /static/*
            pathType: ImplementationSpecific
          - backend:
              service:
                name: hane
                port:
                  number: 80
            path: /*
            pathType: ImplementationSpecific
...
```

### Добавляем аутентификацию (IAP)

Далее мы хотим разрешать доступ к динамической части приложения только пользователям аутентифцированным в рамках Google домена компании посредством [Google Cloud Identity-Aware Proxy](https://cloud.google.com/iap/docs/concepts-overview) сервиса. Например, это может быть полезно для тестового окружения, к которому имеют доступ только сотрудники QA департамента компании, а всяким роботам и кулхацкерам от ворот поворот.

Включение IAP в рамках GKE ничем не отличается особо от CDN – нужно просто связать ещё один `BackendConfig` ресурс с целевым `Service`.

![GKE Service Split CDN + IAP]({{ "assets/gke-service-split-cdn-iap.svg" | absolute_url }})

Вот так может выглядеть манифест для включения IAP в рамках сервиса:

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: hane-iap
spec:
  iap:
    enabled: true
    oauthclientCredentials:
      secretName: sente
```

и прикручивание его к переименованному `Service`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hane-iap
  labels:
    app.kubernetes.io/name: hane-iap
annotations:
  cloud.google.com/neg: '{"ingress":true}'
  cloud.google.com/backend-config: '{"ports": {"80":"hane-iap"}}'
spec:
  selector:
    app.kubernetes.io/name: hane
...
```

URL карта `Ingress` ресурса поменяется соответственно:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hane
spec:
  rules:
    - host: hane.jp
      http:
        paths:
          - backend:
              service:
                name: hane-static
                port:
                  number: 80
            path: /static/*
            pathType: ImplementationSpecific
          - backend:
              service:
                name: hane-iap
                port:
                  number: 80
            path: /*
            pathType: ImplementationSpecific
...
```

Стоит отметить, что CDN и IAP нельзя включить одновременно для одного и того же сервиса. У меня есть предположение касательно этого ограничения. Если бы первым отрабатывал CDN, то авторизированный IAP ответ мог бы позже выдаться из кеша неавторизированному пользователю. Т.е. у пользователя уже отобрали права на доступ к приложению, а он всё ещё может с ним работать пока не протухнет кеш. И наоборот, если бы IAP отрабатывал первым, то это бы сильно замедлило отдачу контента из CDN, т.к. каждый запрос проходил бы предварительную аутентификацию и авторизацию.

### Открываем чёрный ход в IAP

Далее мы хотим открыть доступ всем неаутентифицированным пользователям к некоторым эндпоинтам закрытого IAP приложения. Например, наши партнёры по-прежнему хотят видеть текущую версию приложения по пути `/version`, пока они ещё не интегрировали IAP аутентификацию со своей стороны. Другими словами нам надо сварганить белы список эндпоинтов для VIP клиентов ^_^ В IAP имеется для этих целей [Context-Aware Access](https://cloud.google.com/iap/docs/cloud-iap-context-aware-access-howto) фича, но [IAM условия](https://cloud.google.com/iam/docs/conditions-overview) используемые под капотом не канают для всех пользователей (**allUsers**). [А было бы здорово](https://issuetracker.google.com/issues/190789511). Но это не беда, ведь мы уже умеем резать сервисы налево и направо, верно?

![GKE Service Split CDN + IAP + Whitelist]({{ "assets/gke-service-split-cdn-iap-whitelist.svg" | absolute_url }})

Вернём назад первоначальный `Service` и поменяем URL карту `Ingress` соответственно:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hane
spec:
  rules:
    - host: hane.jp
      http:
        paths:
          - backend:
              service:
                name: hane-static
                port:
                  number: 80
            path: /static/*
            pathType: ImplementationSpecific
          - backend:
              service:
                name: hane
                port:
                  number: 80
            path: /version
            pathType: ImplementationSpecific
          - backend:
              service:
                name: hane-iap
                port:
                  number: 80
            path: /*
            pathType: ImplementationSpecific
...
```

# Итог

В результате всех метаморфоз у нас получается 3 `Service` c соответствующими привязанными `BackendConfig`, которые смотрят в один и тот же `Deployment`. В принципе сервисы много кушать не просят (это по сути прописанные правила в kube-proxy), так что данный подход вполне годный для массового использования. Хотя конечно моя декларативная душа хочет определить все правила в рамках аннтоаций одного `Service` или `BackendObject` ресурса, пока приходится заниматься расчленёнкой.
