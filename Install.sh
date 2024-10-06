#!/bin/bash
tput sgr0; clear

## Load Seedbox Components
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# Check if Seedbox Components is successfully loaded
if [ $? -ne 0 ]; then
	echo "Component ~Seedbox Components~ failed to load"
	echo "Check connection with GitHub"
	exit 1
fi

## Load loading animation
source <(wget -qO- https://raw.githubusercontent.com/Silejonu/bash_loading_animations/main/bash_loading_animations.sh)
# Check if bash loading animation is successfully loaded
if [ $? -ne 0 ]; then
	fail "Component ~Bash loading animation~ failed to load"
	fail_exit "Check connection with GitHub"
fi
# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

## Install function
install_() {
info_2 "$2"
BLA::start_loading_animation "${BLA_classic[@]}"
$1 1> /dev/null 2> $3
if [ $? -ne 0 ]; then
	fail_3 "FAIL" 
else
	info_3 "Successful"
	export $4=1
fi
BLA::stop_loading_animation
}

## Installation environment Check
info "Checking Installation Environment"
# Check Root Privilege
if [ $(id -u) -ne 0 ]; then 
    fail_exit "This script needs root permission to run"
fi

# Linux Distro Version check
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	OS=Debian
	VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
	OS=SuSe
elif [ -f /etc/redhat-release ]; then
	OS=Redhat
else
	OS=$(uname -s)
	VER=$(uname -r)
fi

if [[ ! "$OS" =~ "Debian" ]] && [[ ! "$OS" =~ "Ubuntu" ]]; then	#Only Debian and Ubuntu are supported
	fail "$OS $VER is not supported"
	info "Only Debian 10+ and Ubuntu 20.04+ are supported"
	exit 1
fi

if [[ "$OS" =~ "Debian" ]]; then	#Debian 10+ are supported
	if [[ ! "$VER" =~ "10" ]] && [[ ! "$VER" =~ "11" ]] && [[ ! "$VER" =~ "12" ]]; then
		fail "$OS $VER is not supported"
		info "Only Debian 10+ are supported"
		exit 1
	fi
fi

if [[ "$OS" =~ "Ubuntu" ]]; then #Ubuntu 20.04+ are supported
	if [[ ! "$VER" =~ "20" ]] && [[ ! "$VER" =~ "22" ]] && [[ ! "$VER" =~ "23" ]]; then
		fail "$OS $VER is not supported"
		info "Only Ubuntu 20.04+ is supported"
		exit 1
	fi
fi

## Read input arguments
while getopts "u:p:c:q:l:rbvx3oh" opt; do
  case ${opt} in
	u ) # process option username
		username=${OPTARG}
		;;
	p ) # process option password
		password=${OPTARG}
		;;
	c ) # process option cache
		cache=${OPTARG}
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		#Converting the cache to qBittorrent's unit (MiB)
		qb_cache=$cache
		;;
	q ) # process option cache
		qb_install=1
		qb_ver=("qBittorrent-${OPTARG}")
		;;
	l ) # process option libtorrent
		lib_ver=("libtorrent-${OPTARG}")
		#Check if qBittorrent version is specified
		if [ -z "$qb_ver" ]; then
			warn "You must choose a qBittorrent version for your libtorrent install"
			qb_ver_choose
		fi
		;;
	r ) # process option autoremove
		autoremove_install=1
		;;
	b ) # process option autobrr
		autobrr_install=1
		;;
	v ) # process option vertex
		vertex_install=1
		;;
	x ) # process option bbr
		unset bbrv3_install
		bbrx_install=1	  
		;;
	3 ) # process option bbr
		unset bbrx_install
		bbrv3_install=1
		;;
	o ) # process option port
		if [[ -n "$qb_install" ]]; then
			need_input "Please enter qBittorrent port:"
			read qb_port
			while true
			do
				if ! [[ "$qb_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter qBittorrent port:"
					read qb_port
				else
					break
				fi
			done
			need_input "Please enter qBittorrent incoming port:"
			read qb_incoming_port
			while true
			do
				if ! [[ "$qb_incoming_port" =~ ^[0-9]+$ ]]; then
						warn "Port must be a number"
						need_input "Please enter qBittorrent incoming port:"
						read qb_incoming_port
				else
					break
				fi
			done
		fi
		if [[ -n "$autobrr_install" ]]; then
			need_input "Please enter autobrr port:"
			read autobrr_port
			while true
			do
				if ! [[ "$autobrr_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter autobrr port:"
					read autobrr_port
				else
					break
				fi
			done
		fi
		if [[ -n "$vertex_install" ]]; then
			need_input "Please enter vertex port:"
			read vertex_port
			while true
			do
				if ! [[ "$vertex_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter vertex port:"
					read vertex_port
				else
					break
				fi
			done
		fi
		;;
	h ) # process option help
		info "Help:"
		info "Usage: ./Install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -b -v -r -3 -x -p"
		info "Example: ./Install.sh -u jerry048 -p 1LDw39VOgors -c 3072 -q 4.3.9 -l v1.2.19 -b -v -r -3"
		source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
		seperator
		info "Options:"
		need_input "1. -u : Username"
		need_input "2. -p : Password"
		need_input "3. -c : Cache Size for qBittorrent (unit:MiB)"
		echo -e "\n"
		need_input "4. -q : qBittorrent version"
		need_input "Available qBittorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${qb_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "5. -l : libtorrent version"
		need_input "Available qBittorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${lib_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "6. -r : Install autoremove-torrents"
		need_input "7. -b : Install autobrr"
		need_input "8. -v : Install vertex"
		need_input "9. -x : Install BBRx"
		need_input "10. -3 : Install BBRv3"
		need_input "11. -p : Specify ports for qBittorrent, autobrr and vertex"
		need_input "12. -h : Display help message"
		exit 0
		;;
	\? ) 
		info "Help:"
		info_2 "Usage: ./Install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -b -v -r -3 -x -p"
		info_2 "Example ./Install.sh -u jerry048 -p 1LDw39VOgors -c 3072 -q 4.3.9 -l v1.2.19 -b -v -r -3"
		exit 1
		;;
	esac
done

# System Update & Dependencies Install
info "Start System Update & Dependencies Install"
update

## Install Seedbox Environment
tput sgr0; clear
info "Start Installing Seedbox Environment"
echo -e "\n"


# qBittorrent
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
# Check if qBittorrent install is successfully loaded
if [ $? -ne 0 ]; then
	fail_exit "Component ~qBittorrent install~ failed to load"
fi

if [[ ! -z "$qb_install" ]]; then
	## Check if all the required arguments are specified
	#Check if username is specified
	if [ -z "$username" ]; then
		warn "Username is not specified"
		need_input "Please enter a username:"
		read username
	fi
	#Check if password is specified
	if [ -z "$password" ]; then
		warn "Password is not specified"
		need_input "Please enter a password:"
		read password
	fi
	## Create user if it does not exist
	if ! id -u $username > /dev/null 2>&1; then
		useradd -m -s /bin/bash $username
		# Check if the user is created successfully
		if [ $? -ne 0 ]; then
			warn "Failed to create user $username"
			return 1
		fi
	fi
	chown -R $username:$username /home/$username
	#Check if cache is specified
	if [ -z "$cache" ]; then
		warn "Cache is not specified"
		need_input "Please enter a cache size (in MB):"
		read cache
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		qb_cache=$cache
	fi
	#Check if qBittorrent version is specified
	if [ -z "$qb_ver" ]; then
		warn "qBittorrent version is not specified"
		qb_ver_check
	fi
	#Check if libtorrent version is specified
	if [ -z "$lib_ver" ]; then
		warn "libtorrent version is not specified"
		lib_ver_check
	fi
	#Check if qBittorrent port is specified
	if [ -z "$qb_port" ]; then
		qb_port=8080
	fi
	#Check if qBittorrent incoming port is specified
	if [ -z "$qb_incoming_port" ]; then
		qb_incoming_port=45000
	fi

	## qBittorrent & libtorrent compatibility check
	qb_install_check

	## qBittorrent install
	install_ "install_qBittorrent_ $username $password $qb_ver $lib_ver $qb_cache $qb_port $qb_incoming_port" "Installing qBittorrent" "/tmp/qb_error" qb_install_success
fi

# autobrr Install
if [[ ! -z "$autobrr_install" ]]; then
	install_ install_autobrr_ "Installing autobrr" "/tmp/autobrr_error" autobrr_install_success
fi

# vertex Install
if [[ ! -z "$vertex_install" ]]; then
	install_ install_vertex_ "Installing vertex" "/tmp/vertex_error" vertex_install_success
fi

# autoremove-torrents Install
if [[ ! -z "$autoremove_install" ]]; then
	install_ install_autoremove-torrents_ "Installing autoremove-torrents" "/tmp/autoremove_error" autoremove_install_success
fi

seperator

## Tunning
info "Start Doing System Tunning"
install_ tuned_ "Installing tuned" "/tmp/tuned_error" tuned_success
install_ set_txqueuelen_ "Setting txqueuelen" "/tmp/txqueuelen_error" txqueuelen_success
install_ set_file_open_limit_ "Setting File Open Limit" "/tmp/file_open_limit_error" file_open_limit_success

# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
	warn "Virtualization is detected, skipping some of the tunning"
	install_ disable_tso_ "Disabling TSO" "/tmp/tso_error" tso_success
else
	install_ set_disk_scheduler_ "Setting Disk Scheduler" "/tmp/disk_scheduler_error" disk_scheduler_success
	install_ set_ring_buffer_ "Setting Ring Buffer" "/tmp/ring_buffer_error" ring_buffer_success
fi
install_ set_initial_congestion_window_ "Setting Initial Congestion Window" "/tmp/initial_congestion_window_error" initial_congestion_window_success
install_ kernel_settings_ "Setting Kernel Settings" "/tmp/kernel_settings_error" kernel_settings_success



# BBRx
if [[ ! -z "$bbrx_install" ]]; then
	# Check if Tweaked BBR is already installed
	if [[ ! -z "$(lsmod | grep bbrx)" ]]; then
		warn echo "Tweaked BBR is already installed"
	else
		install_ install_bbrx_ "Installing BBRx" "/tmp/bbrx_error" bbrx_install_success
	fi
fi

# BBRv3
if [[ ! -z "$bbrv3_install" ]]; then
	install_ install_bbrv3_ "Installing BBRv3" "/tmp/bbrv3_error" bbrv3_install_success
fi

## Configue Boot Script
info "Start Configuing Boot Script"
touch /root/.boot-script.sh && chmod +x /root/.boot-script.sh
cat << EOF > /root/.boot-script.sh
#!/bin/bash
sleep 120s
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# Check if Seedbox Components is successfully loaded
if [ \$? -ne 0 ]; then
	exit 1
fi
set_txqueuelen_
# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ \$? -eq 0 ]; then
	disable_tso_
else
	set_disk_scheduler_
	set_ring_buffer_
fi
set_initial_congestion_window_
EOF
# Configure the script to run during system startup
cat << EOF > /etc/systemd/system/boot-script.service
[Unit]
Description=boot-script
After=network.target

[Service]
Type=simple
ExecStart=/root/.boot-script.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable boot-script.service


seperator

## Finalizing the install
info "Seedbox Installation Complete"
publicip=$(curl -s https://ipinfo.io/ip)

# Display Username and Password
# qBittorrent
if [[ ! -z "$qb_install_success" ]]; then
	info "qBittorrent installed"
	boring_text "qBittorrent WebUI: http://$publicip:$qb_port"
	boring_text "qBittorrent Username: $username"
	boring_text "qBittorrent Password: $password"
	echo -e "\n"
fi
# autoremove-torrents
if [[ ! -z "$autoremove_install_success" ]]; then
	info "autoremove-torrents installed"
	boring_text "Config at /home/$username/.config.yml"
	boring_text "Please read https://autoremove-torrents.readthedocs.io/en/latest/config.html for configuration"
	echo -e "\n"
fi
# autobrr
if [[ ! -z "$autobrr_install_success" ]]; then
	info "autobrr installed"
	boring_text "autobrr WebUI: http://$publicip:$autobrr_port"
	echo -e "\n"
fi
# vertex
if [[ ! -z "$vertex_install_success" ]]; then
	info "vertex installed"
	boring_text "vertex WebUI: http://$publicip:$vertex_port"
	boring_text "vertex Username: $username"
	boring_text "vertex Password: $password"
	echo -e "\n"
fi
# BBR
if [[ ! -z "$bbrx_install_success" ]]; then
	info "BBRx successfully installed, please reboot for it to take effect"
fi

if [[ ! -z "$bbrv3_install_success" ]]; then
	info "BBRv3 successfully installed, please reboot for it to take effect"
fi

exit 0

