docker build -t teaminterface .
docker build -t teaminterface_prod priv/prod-docker/
docker tag teaminterface_prod master1:5000/cromu/teaminterface
docker push master1:5000/cromu/teaminterface
