set -e

USER=fcamel

cd /home
sudo mkdir hg
sudo chown $USER:$USER hg
cd hg
mkdir extensions
cd extensions
hg clone https://bitbucket.org/tksoh/hgshelve
hg clone https://bitbucket.org/durin42/histedit
hg clone https://bitbucket.org/durin42/hgsubversion
