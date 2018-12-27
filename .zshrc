export LOCAL_DATABASE_PASSWORD="hello"

dip() {
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1 && \
		docker port $1
}

sdb() {
	if [ ! -f bin/console ]; then
		echo "You're not at the root of a Symfony project!"
		return
	fi

	if [ -f var/data.db ]; then
		rm var/data.db
		touch var/data.db
	else
		echo "doctrine:database:drop ..."
		php bin/console doctrine:database:drop --force 1> /dev/null
	fi

	echo "doctrine:database:create ..."
	php bin/console d:d:c 1> /dev/null
	if [ ! $? -eq 0 ]; then echo 'an error happened.'; return; fi
	echo "doctrine:schema:update --force ..."
	php bin/console d:s:u --force 1> /dev/null
	if [ ! $? -eq 0 ]; then echo 'an error happened.'; return; fi
	echo "doctrine:fixtures:load --append ..."
	php bin/console d:f:l --append | grep -v "new " | grep -v "update "
	if [ ! $? -eq 0 ]; then echo 'an error happened.'; return; fi
}

composer() {
	docker run --rm --interactive --tty \
		--volume $PWD:/app \
		--volume $COMPOSER_HOME:/tmp \
		--volume $SSH_AUTH_SOCK:/ssh-auth.sock \
		--volume /etc/passwd:/etc/passwd:ro \
		--volume /etc/group:/etc/group:ro \
		--user $(id -u):$(id -g) \
		--env SSH_AUTH_SOCK=/ssh-auth.sock \
		composer $@ --working-dir=/app
}

mariadb() {
	CONTAINER_NAME="mariadb_database"

	if [ "$(docker container list --all | grep $CONTAINER_NAME)" ]; then
		docker container stop $CONTAINER_NAME 1> /dev/null
		yes | docker container prune 1> /dev/null
	fi

	docker run -d -p 3306:3306 \
		-e MYSQL_ROOT_PASSWORD=$DATABASE_PASSWORD \
		--name $CONTAINER_NAME mariadb 1> /dev/null

	docker ps -a --format "{{.ID}}: {{.Names}}" | grep $CONTAINER_NAME
	dip $CONTAINER_NAME
}

rabbitmq() {
	CONTAINER_NAME="rabbitmq"

	if [ "$(docker container list --all | grep $CONTAINER_NAME)" ]; then
		docker container stop $CONTAINER_NAME 1> /dev/null
		yes | docker container prune 1> /dev/null
	fi

	docker run -d \
		-p 15672:15672 \
		-p 4369:4369 \
		-p 5671:5671 \
		-p 25672:25672 \
		-p 5672:5672 \
		--hostname local-rabbit \
		--name $CONTAINER_NAME rabbitmq:3-management 1> /dev/null

	docker ps -a --format "{{.ID}}: {{.Names}}" | grep $CONTAINER_NAME
	dip $CONTAINER_NAME
}

phpd() {
	docker run -it --rm -p 8000:8000 -v "$PWD":/var/www -w /var/www php $@
}

yarnd() {
	docker run -it --rm --name yarn -v "$PWD":/usr/src/app -w /usr/src/app node yarn $@
}
