default['consul']['docker_image'] = 'dennybaa/consul:0.4.0'    
default['consul']['bootstrap_expect'] = 3
default['consul']['join_servers']    = []
default['consul']['join_wan']        = false

default['consul']['host_config_dir'] = "/var/lib/consul/config"
default['consul']['host_data_dir']   = "/var/lib/consul/data"
default['consul']['encrypt_key']     = nil
default['consul']['gomaxprocs']      = node['cpu']['total']
default['consul']['advertise_on']    = nil
default['consul']['datacenter']      = 'dc1'
default['consul']['dns_port']        = 53
default['consul']['dns_recursor']    = '8.8.8.8'
default['consul']['ui_enabled']      = true
default['consul']['agent_mode']      = :client

default['consul']['ca']['cookbook'] = 'consul'
default['consul']['ca']['config']   = {}
