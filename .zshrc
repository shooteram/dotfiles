export ZSH="$HOME/.oh-my-zsh"

source ~/.env_vars
source ~/.db

ZSH_THEME="limpide"

plugins=(
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

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
		bin/console doctrine:database:drop --force
		# 1> /dev/null
	fi

	echo "doctrine:database:create ..."
	bin/console d:d:c
	if [ ! $? -eq 0 ]; then echo 'an error happened.'; return; fi

	echo "doctrine:schema:update --force ..."
	bin/console d:s:u --force
	if [ ! $? -eq 0 ]; then echo 'an error happened.'; return; fi

	echo "doctrine:fixtures:load --append ..."
	bin/console d:f:l --append
	if [ ! $? -eq 0 ]; then
		bin/console hautelook:fixtures:load --append
	fi
}

glt() {
	git tag --sort=v:refname | tail -1
}

source ~/.dockerrc
