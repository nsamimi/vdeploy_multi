#!/bin/bash
source ~/bin/color.conf

set -e

BASE="/home/mobaxterm/projects"
CNT=0

echo -n "Project name [test]? "
read -et 30 PROJ
# echo ${PROJ}
if [ "${PROJ}" == "" ]; then
  PROJ="test"
fi
# echo ${PROJ}
PPATH=${BASE}/${PROJ}
# echo ${PPATH}

if [ -d "${PPATH}" ];then
  echo "It appears this is a existing project ..."
  echo -en "Continue [y/n]? "
  read -e ANS
  if [ "${ANS}" != "y" ]; then
    exit
  fi
fi
# echo ${PPATH}

if [ ! -d "${PPATH}" ]; then
  mkdir -p ${PPATH}
  mkdir ${PPATH}/provision
  touch ${PPATH}/provision/provision.sh
# else
#  mkdir ${PPATH}/provision
#  touch ${PPATH}/provision/provision.sh
fi

VFILE="${PPATH}/Vagrantfile"
# echo ${VFILE}

if [ -e "${VFILE}" ]; then
  echo -en "Delete existing Vagrantfile [y/n]? "
  read -e ANS
  if [ "${ANS}" == "y" ]; then
    rm ${VFILE}
  fi
fi

echo -n "Number of servers? "
read -e CNT
# echo ${CNT}
echo "Vagrant.configure("2") do |config|" >${VFILE}
while [ $[CNT] -ne 0 ]
do
  echo -n "Hostname? "
  read -e VM
  NODASH=$(echo $VM |sed -e 's/-//g; s/_//g')
# echo ${NODASH}

# if [ -f /tmp/os.txt ]; then
  if [ -e /tmp/os.txt ]; then
    cat /tmp/os.txt
  else
    # vagrant box list |awk '{print $1}' |sort |uniq |tee /tmp/os.txt
    vagrant box list |tee /tmp/os.txt
  fi
  echo
  echo -n "O.S.? "
  read -e OS
# echo ${OS}  

  echo -n "Version? "
  read -e VER
# echo ${VER}  

  echo -n "CPU [2]? "
  read -e CPU
# echo ${CPU}
  if [ "${CPU}" == "" ]; then
    CPU=2
  fi

  echo -n "Memory (bytes) [1024]? "
  read -e MEM
# echo ${MEM}
  if [ "${MEM}" == "" ]; then
    MEM=1024
  fi

  echo -n "Network [192.168.56.0]? "
  read -e NET
  if [ "${NET}" == "" ]; then
    NET="192.168.56.0"
  fi
  NET=$(echo ${NET} |sed -e 's/\.0//')
# echo ${NET}

  echo ""
  echo -e "Summary of server ${Yellow}${VM}${NC} settings:"
  echo -e "\t${Red}Project:${NC}\t${PROJ}\n\t${Red}O.S.:${NC}\t\t${OS}\n\t${Red}Version:${NC}\t${VER}\n\t${Red}CPU:${NC}\t\t${CPU}\n\t${Red}Memory:${NC}\t\t${MEM}\n\t${Red}Network:${NC}\t${NET}.0"
  echo -en "Looks good [y/n]? "
  read -e ANS
  if [ "$ANS" == "y" ]; then
    cat <<EOF >>${VFILE}
  config.vm.box = "${OS}"
EOF
  if [ ! -z "${VER}" ]; then
    cat <<EOF >>${VFILE}
  config.vm.box_version = "${VER}"

EOF
  else
    cat <<EOF >>${VFILE}
    
EOF
  fi

    cat <<EOF >>${VFILE}
  config.vm.define "${NODASH}" do |${NODASH}|
    ${NODASH}.vm.hostname = "${VM}"
    ${NODASH}.vm.network :private_network, ip: "${NET}.8${CNT}"
    ${NODASH}.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--memory", ${MEM}]
      v.customize ["modifyvm", :id, "--cpus", ${CPU}]
    end
  end

EOF
    CNT=$((${CNT} - 1))
  else
    echo ""
    echo "Please try again ..."
    echo ""
  fi
done

cat <<EOF >>${VFILE}
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
  SHELL

  config.vm.provision "shell", path: "provision/provision.sh"
end
EOF

if [ -f /tmp/os.txt ]; then
# rm /tmp/os.txt
# Delete the file if it is 1 hour old.
  find /tmp -maxdepth 1 -mmin +59 -name os.txt -type f -exec rm -f {} \;
fi  

cd ${PPATH}
echo
cat ${VFILE}
echo
vagrant status

# Populating provision.sh with some basic commands.
cat << EOF > ${PPATH}/provision/provision.sh
#
# How to re-run provision again
# vagrant provision <hostname>
#

BASHRC() {
  echo  >>\${1}
  echo set -o vi >>\${1}
  echo alias c='clear' >>\${1}
  echo  >>\${1}

}

BASHRC /home/vagrant/.bashrc
BASHRC /root/.bashrc

#apt-get update && apt-get upgrade -y
apt-get upgrade -y

apt-get install -y tree git

#curl -L https://bootstrap.saltstack.com -o install_salt.sh
#sh install_salt.sh -P -M

EOF

echo -e "${Green}"
cat << EOF
*************************************************************************
* Check if the Vagrantfile looks good!
* Modify the ${PROJ}/provision/provision.sh for post configuration!
* Run 'vagrant up'
*************************************************************************
EOF
echo -e "${NC}"
# vagrant ssh-config
