#!/usr/bin/python

# This script:
#  - retrieves current classification information (node groups)
#  - determines the current setup for the PE Master node group
#  - extracts the currently applied classes and group ID
#  - determines which pe_repo::platform classes are already applied in that
#    group
#  - adds (if necessary) the el_7_x86_64, windows_x86_64, and ubuntu_1604_amd64
#    classes to that group
#  - creates a new group (if it doesn't already exist) called "git" (for the
#    git server that holds the control repository)
#  - creates a rule matching systems with a pp_role extension (in the cert) of
#    "git" to that new group
#  - runs the Puppet agent if any changes were made.
#
# Note that it expects to be run on a Puppet master named "pe-master", and
# that "pe-master" will resolve to the appropriate IP address.

import urllib2, ssl, json, sys


# GET: /classifier-api/v1/groups
#  Cert: /etc/puppetlabs/puppet/ssl/certs/hostname.pem
#  Private key: /etc/puppetlabs/puppet/ssl/private_keys/hostname.pem
#  CA cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem

# curl -X GET -H "Content-Type: application/json"

# This will be running on CentOS 7, which comes with Python 2.7.5 by default.
# We can't assume anything later. Fortunately, this version of Python has
# SSL contexts available (whether patched in by Redhat or by default, I don't
# really care...)

sslcontext = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH, cafile='/etc/puppetlabs/puppet/ssl/certs/ca.pem')

# XXX: In a real world environment, I'd write code that trawls through the
# directory listing to find the certificate and private key, rather than hard
# coding the FQDN. This at least demonstrates the general idea, though.
sslcontext.load_cert_chain('/etc/puppetlabs/puppet/ssl/certs/pe-master.fritz.box.pem', keyfile='/etc/puppetlabs/puppet/ssl/private_keys/pe-master.fritz.box.pem')

opener = urllib2.build_opener(urllib2.HTTPSHandler(context = sslcontext))
urllib2.install_opener(opener)

# Start by refreshing the classes.
class_refresh_url = "https://pe-master:4433/classifier-api/v1/update-classes"
rest_request = urllib2.Request(class_refresh_url, '', { 'Content-Type': 'application/json' })
result = urllib2.urlopen(rest_request).getcode()

if (result <> 201):
  print "Unable to refresh classes. Bailing."
  sys.exit(1)

url = "https://pe-master:4433/classifier-api/v1/groups"

data = urllib2.urlopen(url)

parsed_data = json.load(data)

desired_pe_master_data = None
git_data = None
all_nodes_id = None
for i in parsed_data:
  if i['name'] == 'PE Master':
    desired_pe_master_data = i
  if i['name'] == 'git repository':
    git_data = i
  if i['name'] == 'All Nodes':
    all_nodes_id = i['id']

if not desired_pe_master_data:
  sys.stderr.write('Could not find the PE Master node group. Bailing.\n')
  sys.exit(1) # We couldn't find the PE Master group; don't try to diagnose

# ['classes'] holds the list of classes. ['id'] gives the id that we need
# for a later submission to adjust the classes.

target_classes = [ 'pe_repo::platform::el_7_x86_64', 'pe_repo::platform::windows_x86_64', 'pe_repo::platform::ubuntu_1604_amd64', 'pe_git::client' ]
#  - adds (if necessary) the el_7_x86_64, windows_x86_64, and ubuntu_1604_amd64
needed_classes = False

for i in target_classes:
  if i not in desired_pe_master_data['classes']:
    needed_classes = True
    desired_pe_master_data['classes'][i] = { }

if not needed_classes:
  print 'All needed classes are already set. No action required.'
  sys.exit(0)

update_url = url + '/' + desired_pe_master_data['id']
print update_url

# Trim back the data to just the classes; we don't need to apply the entire
# group, just the classes.
keys = desired_pe_master_data.keys()
for i in keys:
  if i not in ['id', 'classes']:
    del desired_pe_master_data[i]

# Needs to be a POST request. Content-Type: application/json
json_post_data = json.dumps(desired_pe_master_data)

rest_request = urllib2.Request(update_url, json_post_data, { 'Content-Type': 'application/json' })

result = urllib2.urlopen(rest_request).getcode()

if result <> 200:
  sys.stderr.write('Return code ' + str(result) + ' trying to update classes. Bailing.')
  sys.exit(1)

if not git_data:
  new_git_data = {
    "name": "git repository",
    "description": "Node group for the central git repository, holding the control and module repositories for Puppet",
    "parent": all_nodes_id,
    "rule": ["and", ["=", ["trusted", "extensions", "pp_role"], "git"]],
    "classes": { "pe_git::server": { } }
  }
  json_post_data = json.dumps(new_git_data)
  rest_request = urllib2.Request(url, json_post_data, { 'Content-Type': 'application/json' })
  result = urllib2.urlopen(rest_request)
  print result.getcode()
