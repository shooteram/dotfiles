db() {
    if [ ! -z "$DATABASE_IP_ADDRESS" ]; then
        mysql -h $DATABASE_IP_ADDRESS $@
    else
        echo 'The environment variable "DATABASE_IP_ADDRESS" is not defined.'
    fi
}
