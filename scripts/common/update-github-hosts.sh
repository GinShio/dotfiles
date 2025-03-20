source $(dirname $0)/common.sh
set -o allexport
source $(dirname $0)/proxy.sh
set +o allexport
sudo -Sv <<<$ROOT_PASSPHRASE
sudo cp /etc/hosts.bkp /etc/hosts
sudo -E bash -c "curl -s https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |tee -a /etc/hosts"
sudo -k
