#domain = 'psehomework.localdomain'

nodes = [
  { :hostname => 'pe-master',        :ip => '10.0.42.240', :box => 'generic/centos7', :ram => 8192, :provision_pe => true },
  { :hostname => 'pe-agent-win2012', :ip => '10.0.42.241', :box => 'mwrock/Windows2012R2', :ram => 2048, :provision => 'install-puppet-windows.ps1' },
  { :hostname => 'pe-agent-centos7', :ip => '10.0.42.242', :box => 'generic/centos7', :provision => 'install-puppet-linux.sh' },
  { :hostname => 'pe-agent-ubuntu1604', :ip => '10.0.42.243', :box => 'ubuntu/xenial64', :provision => 'install-puppet-linux.sh' }
]

Vagrant.configure("2") do |config|
  nodes.each do |node|
    config.vm.define node[:hostname] do |nodeconfig|
      nodeconfig.vm.box = node[:box]
      nodeconfig.vm.hostname = node[:hostname]
      nodeconfig.vm.network :public_network
      nodeconfig.vm.network :private_network, ip: node[:ip]

      if (node[:ram])
        nodeconfig.vm.provider "hyperv" do |hv|
          hv.memory = node[:ram]
          hv.maxmemory = node[:ram]
        end
        nodeconfig.vm.provider "virtualbox" do |v|
          v.memory = node[:ram]
        end
      end
      if (node[:provision_pe])
        nodeconfig.vm.provision "file", source:"puppet-enterprise-2018.1.3-el-7-x86_64.tar.gz", destination: "$HOME/pe.tgz"
        nodeconfig.vm.provision "file", source:"custom-pe.conf", destination: "$HOME/custom-pe.conf"
        nodeconfig.vm.provision "file", source:"pe_git", destination: "$HOME/pe_git"
        nodeconfig.vm.provision :shell, path: "install-pe.sh"
        nodeconfig.vm.provision :shell, path: "pe-classification.py"
        nodeconfig.vm.provision :shell, inline: "/usr/local/bin/puppet agent -t || exit 0"
      end
      if (node[:provision])
        nodeconfig.vm.provision :shell, path: node[:provision]
      end
    end
  end

  # yeah, this probably should be in the general list of hosts, but
  # because I'm playing around with trusted facts (CSR attributes),
  # I've split it out as a matter of convenience.
  config.vm.define "git" do |git|
    git.vm.box = "generic/centos7"
    git.vm.hostname = "git"
    git.vm.network :public_network
    git.vm.network :private_network, ip: "10.0.42.244"
    git.vm.provision :file, source:"git_csr_attributes.yaml", destination: "$HOME/csr_attributes.yaml"
    git.vm.provision :file, source:"control-repo", destination: "$HOME/control-repo"
    git.vm.provision :shell, path: "install-puppet-linux.sh"
  end
end
