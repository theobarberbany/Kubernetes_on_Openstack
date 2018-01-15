#### Deploying an Ingress Controller (Traefik) using Helm
##### Prerequisites

1. Working Kubernetes cluster, deployed as explained in the kubespray tutorial
2. Helm and Tiller installed. [See here](../helm/) 


##### Deployment

This a heavily cut down version of [this guide](http://hypernephelist.com/2017/10/17/getting-started-with-traefik-and-k8s-using-acs.html). It is worth reading.

###### tl;dr

1. `helm init --upgrade` -- Ensure Helm and Tiller are running properly.
2. `helm install --namespace kube-system --set dashboard.enabled=true,dashboard.domain=ingress.k8s,memoryRequest=300,memoryLimit=400 stable/traefik`  
    * I've changed the domain because I can't ever remember how to spell Traefik 
    * This specifies to Helm to modify the configmap 
    * For more information see: https://github.com/kubernetes/charts/tree/master/stable/traefik 
    
3. `helm list` and obtain the name of your deployment, mine was `wizened-lynx`
4. `kubectl describe svc wizened-lynx-traefik --namespace kube-system | grep Ingress | awk '{print $4}'` returns the url of the loadbalancer: 

```
$ kubectl describe svc wizened-lynx-traefik --namespace kube-system | grep Ingress | awk '{print $4}'

173.172.27.93.1
```

Now we can access the ui by editing `/etc/hosts` 

```
...

173.172.27.93.1    ingress.k8s

...
```

And pointing the browser to http://ingress.k8s

The example of deploying Kuard (Kubernetes up and running) can be created by executing the following 

`kubectl create -f kuard.yaml`

```yaml
$ cat kuard.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kuard-deployment
  labels:
    app: kuard
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kuard
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
        - image: gcr.io/kuar-demo/kuard-amd64:1
          name: kuard
          ports:
            - containerPort: 8080
              name: http
---
apiVersion: v1
kind: Service
metadata:
  name: kuard-service
spec:
  selector:
    app: kuard
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard-ingress
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: kuard-service
          servicePort: 80

```