include_recipe 'fig'
include_recipe 'selfpki'
include_recipe 'runit'

package 'conntrack'

[
  node['consul']['host_config_dir'],
  node['consul']['host_data_dir'],
].each do |dir|

  directory dir do
    owner 'root'
    group 'root'
    mode  00755
    recursive true
    action :create
  end

end


# Choose the address where consul will be advertised
if advertise_on = node['consul']['advertise_on']
  advertise_addr = node['network']['interfaces'][advertise_on]['addresses'].
                    find {|addr, data| data['family'] == 'inet'}.first
end
advertise_addr ||= node['ipaddress']


# Choose default arguments
server_args = []
if node['consul']['agent_mode'].to_sym == :server
  server_args << '-server'
  server_args << "-bootstrap-expect #{node['consul']['bootstrap_expect']}"
  server_args << '-ui-dir /ui' if node['consul']['ui_enabled']
end


template "#{node['consul']['host_config_dir']}/consul.json" do
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

# Create host certificate and write ca.crt from cookbook

node.default['selfpki']['openssl_cnf_cookbook'] = 'consul'

if node['consul']['ca']['cookbook'] == 'consul'
  Chef::Log.fatal "Using bundled CA certificate, it's insecure."
end

selfpki 'consul' do
  cookbook node['consul']['ca']['cookbook']
  config   node['consul']['ca']['config']

  key_path  "#{node['consul']['host_config_dir']}/host.key"
  cert_path "#{node['consul']['host_config_dir']}/host.crt"

  server_cert(node['consul']['agent_mode'] == :server)
end

cookbook_file "#{node['consul']['host_config_dir']}/ca.crt" do
  cookbook node['consul']['ca']['cookbook']

  source 'ca.crt'
  owner  'root'
  group  'root'
  mode   00644
end

# Create consul fig environment and start consul
fig 'consul' do
  source 'consul.yaml.erb'

  variables({
    cmd_args: server_args.join(' '),
    advertise_addr: advertise_addr
  })

  not_if { ::File.exist? '/etc/fig.d/consul' }
end

join_args = []
join_to = Array(node['consul']['join_servers'])

if join_to.empty?
  Chef::Log.warn "Join server list is empty, brining up a standalone server"
end  

# We are about to be bootstrapped, so consul environment file doesn't exist.
# Initiate one-off command to join consul cluster.
unless join_to.empty? || ::File.exist?('/etc/fig.d/consul')
  join_args << '-wan' if node['consul']['join_wan']
  join_args << "-rpc-addr=#{advertise_addr}:8400"

  fig 'join consul cluster' do
    action :run
    source 'consul.yaml.erb'
    service 'consul'

    variables(cmd_args: server_args.join(' '))
    run_opts({
      entrypoint: '/bin/consul',
      command: %Q(join #{join_args.join(' ')}  #{join_to.join(' ')})
    })
  end
end

# start runit service
runit_service "consul" do
  action :enable
end
