__dir="$(dirname $_)"
source "$__dir"/func/.dockerrc.sh
source "$__dir"/func/.redmine.sh
source "$__dir"/func/.database.sh
source "$__dir"/func/.git.sh

unset __dir
