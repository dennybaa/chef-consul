default['consul']['bootstrap_expect'] = 3
default['consul']['bootstrap_args']  = ""
default['consul']['host_config_dir'] = "/var/lib/consul-config"
default['consul']['encrypt_key']     = nil
default['consul']['gomaxprocs']      = node['cpu']['total'] > 1 ? 3 : 2
default['consul']['advertise_on']    = nil
default['consul']['datacenter']      = 'dc1'
default['consul']['dns_port']        = 53
default['consul']['dns_recursor']    = '8.8.8.8'
default['consul']['ui_enabled']      = true
default['consul']['agent_mode']      = :client

default['consul']['ca']['cookbook'] = 'consul'
default['consul']['ca']['config']   = {}
