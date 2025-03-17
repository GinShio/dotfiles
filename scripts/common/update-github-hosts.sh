source $(dirname $0)/common.sh
sudo -Sv <<<$ROOT_PASSPHRASE
sudo cp /etc/hosts.bkp /etc/hosts
sudo bash -c "curl -s https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts |sed '1,2d' - |tee -a /etc/hosts"
sudo -k
