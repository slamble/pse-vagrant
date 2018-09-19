cd ~
tar zxf ~vagrant/pe.tgz
cd puppet-enterprise-2018.1.3-el-7-x86_64
./puppet-enterprise-installer -y -q -c ~vagrant/custom-pe.conf

confdir=`/usr/local/bin/puppet config print confdir`
autosignconf=$confdir/autosign.conf

# This is a major security risk: it sets up Puppet to automatically sign
# ALL certificate requests. This would not be done in a real world
# production environment.
cat << EOF > $autosignconf
#!/bin/sh

cert=\$(cat)

exit 0
EOF

chmod 755 $autosignconf

# Set up the firewall rules to allow outside access.
/bin/firewall-cmd --permanent --add-port=8140/tcp
/bin/firewall-cmd --permanent --add-port=443/tcp
/bin/firewall-cmd --permanent --add-port=4433/tcp
/bin/firewall-cmd --permanent --add-port=8081/tcp
/bin/firewall-cmd --permanent --add-port=8142/tcp
/bin/firewall-cmd --permanent --add-port=8143/tcp
/bin/firewall-cmd --reload

# The echo is a workaround: changes will result in a return code of 2,
# which Vagrant considers a failure.
/usr/local/bin/puppet agent -t || echo $?

# Set up an SSH key for later use to access git. This is something of
# an ugly hack; I'd much rather use Puppet to generate and distribute
# the public key, but there's no way to do that in a Puppet manifest.
# So part one, here, sets up the key and modifies the manifest code
# to use the public key; part two relies upon that manifest code having
# been applied, and the git server picking it up.

mkdir -p /etc/puppetlabs/puppetserver/ssh
/usr/bin/ssh-keygen -o -N '' -f /etc/puppetlabs/puppetserver/ssh/id-control_repo
key=`sed -e 's+^[^ ]* ++' -e 's+ [^ ]*$++' < /etc/puppetlabs/puppetserver/ssh/id-control_repo.pub`

# Another rather ugly hack to set up the pe_git classes with the provided ssh
# key.
mv ~vagrant/pe_git /etc/puppetlabs/code/environments/production/modules/
chown -R pe-puppet:pe-puppet /etc/puppetlabs/code/environments/production/modules/pe_git
cd /etc/puppetlabs/code/environments/production/modules/pe_git/manifests
sed -e "s:REPLACE_THIS:$key:" < client.pp.base > client.pp
