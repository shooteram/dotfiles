_network="docker_network"

# check if network exists
docker network inspect $_network &> /dev/null
if [ $? -ne 0 ]; then
	docker network create --subnet=172.19.0.0/16 $_network &> /dev/null
fi

dkr() {
	if [[ $1 == "" ]]; then
		echo "a container name is required to proceed."
		return
	fi

	_container=$1

	if [ "$(docker container list --all | grep $_container)" ]; then
		docker container stop $_container 1> /dev/null
		yes | docker container prune 1> /dev/null
	fi

	kibana_ip_address="172.19.0.30"
	elasticsearch_ip_address="172.19.0.32"

    case $_container in
	kibana)
		docker run -d -p 5601:5601 --net $NETWORK --ip $kibana_ip_address --hostname $_container \
			--name $_container kibana:6.6.0 1> /dev/null
		;;
	rabbitmq)
		docker run -d -p 15672:15672 -p 4369:4369 -p 5671:5671 -p 25672:25672 -p 5672:5672 \
			--net $NETWORK --ip 172.19.0.31 --hostname $_container \
			--name $_container rabbitmq:3-management 1> /dev/null
		;;
	elasticsearch)
		docker run -d -p 9200:9200 -p 9300:9300 \
			-e "discovery.type=single-node" \
			-v/var/docker/elasticsearch/data:/var/lib/elasticsearch/data \
			--net $NETWORK --ip $elasticsearch_ip_address --hostname $_container \
			--name $_container elasticsearch:6.7.1 1> /dev/null
		;;
	phpmyadmin)
		docker run -d -p 8080:80 \
			-e "PMA_HOST=mariadb" --link mariadb:db \
			--net $NETWORK --ip 172.19.0.33 --hostname $_container \
			--name $_container phpmyadmin/phpmyadmin 1> /dev/null
		;;
	mariadb)
		if [ ! -z "$DATABASE_PASSWORD" ]; then
			docker run -d -p 3306:3306 \
				-e "MYSQL_ROOT_PASSWORD=$DATABASE_PASSWORD" \
				-v/var/docker/mysql:/var/lib/mysql \
				--net $NETWORK --ip $DATABASE_IP_ADDRESS --hostname $_container \
				--name $_container mariadb 1> /dev/null
		else
			echo "The environement variable 'DATABASE_PASSWORD' is required."
			return 1
		fi
		;;
	*)
		echo "this container name is unknown"
		return
	esac

	docker ps -a --format "{{.ID}}: {{.Names}}" | grep $_container

    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
        $_container && docker port $_container
}

unset _network _container kibana_ip_address elasticsearch_ip_address
