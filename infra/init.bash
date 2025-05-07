mysql_endpoint=$(terraform output --raw mysql_endpoint)
mysql_host=${mysql_endpoint%%:*}
mysql_username=root
mysql_password=password
mysql_database=myapp



aws eks update-kubeconfig --name final-kluster --region us-east-1
kubectl create secret generic mysql-secret \
  --from-literal=MYSQL_HOST=${mysql_host} \
  --from-literal=MYSQL_USER=${mysql_username} \
  --from-literal=MYSQL_PASSWORD=${mysql_password} \
  --from-literal=MYSQL_DATABASE=${mysql_database}

kubectl delete pod mysql-client


cat init.sql | kubectl run mysql-client --rm -i \
  --image=mysql:8 \
  --restart=Never \
  -- bash -c "mysql -h ${mysql_host} -u ${mysql_username} -p${mysql_password} ${mysql_database}"

exit 0

kubectl run mysql-client --rm -i --tty \
  --image=mysql:8 \
  --restart=Never \
  -- bash -c "mysql -h ${mysql_host} -u ${mysql_username} -p${mysql_password} ${mysql_database}"





