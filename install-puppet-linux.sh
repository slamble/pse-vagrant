cat << EOF >> /etc/hosts
10.0.42.240 pe-master
10.0.42.241 pe-agent-win2012
10.0.42.242 pe-agent-centos7
10.0.42.243 pe-agent-ubuntu1604
EOF
if [ -f ~vagrant/csr_attributes.yaml ]; then
  echo Found csr_attributes, moving in place.
  mkdir -p /etc/puppetlabs/puppet
  mv ~vagrant/csr_attributes.yaml /etc/puppetlabs/puppet/
fi
if [ -f /var/lib/dpkg/lock ]; then
  echo /var/lib/dpkg/lock exists, checking for locks...
  while fuser /var/lib/dpkg/lock > /dev/null 2>&1; do
    sleep 10
  done
  echo All locks clear.
fi
curl -k https://pe-master:8140/packages/current/install.bash | sudo bash
while [ -f /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock ]; do
  sleep 5
done
/usr/local/bin/puppet agent -t
if [ -d ~vagrant/control-repo ]; then
  mv ~vagrant/control-repo ~git/
  chown -R git:git ~git/control-repo
fi
