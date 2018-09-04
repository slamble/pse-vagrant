cd ~
tar zxf ~vagrant/pe.tgz
cd puppet-enterprise-2018.1.3-el-7-x86_64
./puppet-enterprise-installer -y -q -c ~vagrant/custom-pe.conf
fail=$?

if [ $fail -eq 2 ]; then
  fail=0
fi

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

/usr/local/bin/puppet agent -t || echo $?
