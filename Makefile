CLUSTER_NAME=ginflix
VID_NAME=stock_analysis.mp4

cluster-create:
	- kind create cluster --name ${CLUSTER_NAME} --config kind-config.yml --image="kindest/node:v1.23.10@sha256:f047448af6a656fae7bc909e2fab360c18c487ef3edc93f06d78cdfd864b2d12"
	- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
	- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/custom-resources.yaml

clean:
	kind delete clusters ${CLUSTER_NAME}

database:
	kubectl apply -f volumes/database.yml
	kubectl apply -f deployments/database.yml
	kubectl apply -f services/database.yml
_database:
	- kubectl delete -f deployments/database.yml
	- kubectl delete -f volumes/database.yml
	- kubectl delete -f services/database.yml

streamer:
	kubectl apply -f volumes/streamer.yml
	kubectl apply -f deployments/streamer.yml
	kubectl apply -f services/streamer.yml
_streamer:
	- kubectl delete -f deployments/streamer.yml
	- kubectl delete -f volumes/streamer.yml
	- kubectl delete -f services/streamer.yml

web:
	kubectl apply -f deployments/web.yml
	kubectl apply -f services/web.yml
_web:
	- kubectl delete -f deployments/web.yml
	- kubectl delete -f services/web.yml

caddy:
	{ \
		cd reverse-proxy ; \
		docker-compose up -d ; \
	}
down-caddy:
	{\
		cd reverse-proxy ; \
		docker-compose down ; \
	}
_caddy:
	{\
		cd reverse-proxy ; \
		docker-compose down --rmi all ; \
	}

STREAMER:=$(shell kubectl get pods -l run=streamer | awk -F' ' 'NR==2 {print $$1}')
copy:
	kubectl cp videos/${VID_NAME} $(STREAMER):/var/www/html/stock.mp4
	kubectl exec -ti $(STREAMER) -- ls /var/www/html/

start: database streamer web caddy
stop: _database _streamer _web _caddy

+ansible:
	{\
		cd ansible ; \
		ansible-playbook run_app.yml ; \
	}
_ansible:
	{\
		cd ansible ; \
		ansible-playbook clean.yml ; \
	}