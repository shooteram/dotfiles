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
	if [ "$(docker container list --all | grep mariadb_database)" ]; then
		docker container stop mariadb_database 1> /dev/null
		yes | docker container prune 1> /dev/null
	fi

	docker run -d -p 3306:3306 \
		-e MYSQL_ROOT_PASSWORD=$LOCAL_DATABASE_PASSWORD \
		--name mariadb_database mariadb 1> /dev/null

	docker ps -a --format "{{.ID}}: {{.Names}}" | grep mariadb_database
}

phpd() {
	docker run -it --rm -p 8000:8000 -v "$PWD":/var/www -w /var/www php $@
}

yarnd() {
	docker run -it --rm --name yarn -v "$PWD":/usr/src/app -w /usr/src/app node yarn $@
}
