helm uninstall ingress
kubectl delete service/lam
kubectl delete pod/lam
helm install ingress ingress/

docker build -t nathanobert/ark_lam:latest .
docker push nathanobert/ark_lam:latest

#kubectl create -f ubi8_ubi.yaml
kubectl create -f ark_lam.yaml
kubectl expose pod/lam

kubectl wait --for=condition=ready pod -l app=lam --timeout=-1s
kubectl get pods
echo kubectl logs pod/lam
echo kubectl exec -it pod/lam -- bash
