#
# Cookbook Name:: consul
# Recipe:: default
#
# Copyright (C) 2014 Twiket LTD
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'fig'
include_recipe 'selfpki'
include_recipe 'runit'

default_args = []
consul_config_dir = node['consul']['host_config_dir']

# Choose the address where consul will be advertised
if advertise_on = node['consul']['advertise_on']
  advertise_addr = node['network']['interfaces'][advertise_on]['addresses'].
                    find {|addr, data| data['family'] == 'inet'}.first
end
advertise_addr ||= node['ipaddress']

# Choose default arguments
if node['consul']['agent_mode'].to_sym == :server
  default_args << '-server'
  default_args << "-bootstrap-expect #{node['consul']['bootstrap_expect']}"
  default_args << '-ui-dir /ui' if node['consul']['ui_enabled']
end

directory consul_config_dir do
  owner 'root'
  group 'root'
  mode  00755
  action :create
end

template "#{consul_config_dir}/consul.json" do
  source 'consul.json.erb'
  owner  'root'
  group  'root'
  mode   00600
  variables({
    encrypt_key: node['consul']['encrypt_key'],
    advertise_addr: advertise_addr,
    datacenter: node['consul']['datacenter']
  })
end

node.default['selfpki']['openssl_cnf_cookbook'] = 'consul'

if node['consul']['ca']['cookbook'] == 'consul'
  Chef::Log.fatal "Using bundled CA certificate, it's insecure."
end

selfpki 'consul' do
  cookbook node['consul']['ca']['cookbook']
  config   node['consul']['ca']['config']

  key_path  "#{consul_config_dir}/host.key"
  cert_path "#{consul_config_dir}/host.crt"

  server_cert(node['consul']['agent_mode'] == :server)
end

cookbook_file "#{consul_config_dir}/ca.crt" do
  source 'ca.crt'
  owner  'root'
  group  'root'
  mode   00644
end

# Perform bootstrap run
unless (bootstrap_args = Array(node['consul']['bootstrap_args'])).empty?

  fig 'consul-bootstrap-run' do
    action :up
    single_pass true

    source 'consul.yml.erb'

    variables({
      cmd_args: (default_args + bootstrap_args).join(' '),
      advertise_addr: advertise_addr
    })

    # fig is already bootstrapped if default config exists
    not_if { ::File.exist? '/etc/fig.d/default_consul' }
  end

end

fig 'consul' do
  action :up
  source 'consul.yml.erb'

  variables(cmd_args: default_args.join(' '), advertise_addr: advertise_addr)
end

# We don't start runit service, since it's already up
runit_service "consul" do
  action :enable
  restart_on_update false
end
