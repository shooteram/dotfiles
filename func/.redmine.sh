redmine() {
    get_info

    case $1 in
	[a-z\/.:]*issues\/([0-9]*)) handle_link $1; return;;
    lastmessage) _selector=".issue.journals | .[length-1]";;
	link) echo "https://${REDMINE_SERVER}/issues/${_redmine_id}"; return;;
	.) _selector=".";;
	"") _selector=".";;
    *) _selector=".issue.$1";;
	esac

    jq -r $_selector <<< $_response
}

get_info() {
    if is_redmine $1; then
        if [ ! -z "$REDMINE_SERVER" ]; then
            redmine_id true
            _address="https://${REDMINE_SERVER}/issues/${_redmine_id}.json?include=journals"
        else
            echo "[$(date)] REDMINE: The environement variable 'REDMINE_SERVER' is \
nowhere to be seen but it is required." >> /var/log/lastlog
            return 1
        fi

        get_redmine
    fi
}

is_redmine() {
    [[ $(git_prompt_info) == *"/RM"* ]]
}

get_redmine() {
    _filename="/tmp/.redmine_${_redmine_id}"

    if [ -f $_filename ]; then
        _time_diff=1800
        _cur_time=$(date +%s)
        _file_time=$(stat $_filename -c %Y)
        _second_time_diff=$(expr $_cur_time - $_file_time)

        if [[ $_second_time_diff -gt $_time_diff ]]; then
            echo "[$(date)] REDMINE: New update: file '${_filename}' exceeded it's time \
diff (by ${_second_time_diff} seconds)" >> /var/log/lastlog
            send_request
        else _response=$(cat ${_filename}) fi
    else
        echo "[$(date)] REDMINE: New update: file '${_filename}' didn't existed \
before" >> /var/log/lastlog
        send_request
    fi
}

send_request() {
    if [ ! -z "$REDMINE_API_KEY" ]; then
        curl --silent -H 'Content-Type: application/json' \
            -H "X-Redmine-API-Key: ${REDMINE_API_KEY}" \
            $_address -o "${_filename}"

        _response=$(cat ${_filename})
    else
        echo "[$(date)] REDMINE: The environement variable 'REDMINE_API_KEY' is \
nowhere to be seen but it is required." >> /var/log/lastlog
        return 1
    fi
}

handle_link() {
    _redmine_id=$(echo "$1"| grep -Eo "[[:digit:]]{5}")
    _branch="feature/RM${_redmine_id}"

    git checkout $_branch &> /dev/null

    if [[ ! $? -eq 0 ]]; then
        git checkout -b $_branch &> /dev/null
    fi
}

feature() {
    if is_redmine $1; then
        redmine_id true
        echo feature/RM$_redmine_id
    fi
}

redmine_id() {
    _redmine_id=$(git_prompt_info | grep -Eo "[[:digit:]]{5}")

    if [[ "" = $1 ]]; then
        echo $_redmine_id
    fi
}

unset _selector _response _address _redmine_id _branch _filename _time_diff _cur_time _file_time _second_time_diff
