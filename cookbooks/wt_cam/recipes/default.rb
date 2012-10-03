#
# Cookbook Name:: wt_cam
# Recipe:: default
# Author: Kendrick Martin(<kendrick.martin@webtrends.com>)
#
# Copyright 2012, Webtrends
#
# All rights reserved - Do Not Redistribute
# This recipe installs the CAM IIS app

if deploy_mode?
  include_recipe "ms_dotnet4::regiis"
  include_recipe "wt_cam::uninstall"
end

#Properties
install_dir = "#{node['wt_common']['install_dir_windows']}\\Webtrends.Cam"
install_logdir = node['wt_common']['install_log_dir_windows']
log_dir = "#{node['wt_common']['install_dir_windows']}\\logs"
app_pool = node['wt_cam']['app_pool']
pod = node.chef_environment
user_data = data_bag_item('authorization', pod)
auth_cmd = "/section:applicationPools /[name='#{app_pool}'].processModel.identityType:SpecificUser /[name='#{app_pool}'].processModel.userName:#{user_data['wt_common']['ui_user']} /[name='#{app_pool}'].processModel.password:#{user_data['wt_common']['ui_pass']}"
http_port = node['wt_cam']['cam']['port']

iis_pool app_pool do
    pipeline_mode :Integrated
    runtime_version "4.0"
    action [:add, :config]
end

iis_site 'Default Web Site' do
	action [:stop, :delete]
end

iis_pool 'DefaultAppPool' do
    action [:stop, :delete]
end

directory install_dir do
	recursive true
	action :create
end

directory log_dir do
	recursive true
	action :create
end

iis_site 'CAM' do
    protocol :http
    port http_port
	application_pool app_pool
    path install_dir
	action [:add,:start]
	retries 2
end

wt_base_firewall 'CAMWS' do
    protocol "TCP"
    port http_port
    action [:open_port]
end

wt_base_icacls install_dir do
	action :grant
	user user_data['wt_common']['ui_user']
	perm :modify
end

wt_base_icacls log_dir do
	action :grant
	user user_data['wt_common']['ui_user']
	perm :modify
end

if deploy_mode?
  windows_zipfile install_dir do
    source node['wt_cam']['cam']['download_url']
    action :unzip
  end

  template "#{install_dir}\\web.config" do
  	source "web.config.erb"
	variables(
		:db_server => node['wt_cam']['db_server'],
		:db_name   => node['wt_cam']['db_name']
  	)
  end

  template "#{install_dir}\\log4net.config" do
        source "cam.log4net.config.erb"
        variables(
                :log_level => node['wt_cam']['cam']['log_level']
        )
  end

  # add the plugins here
  include_recipe "wt_cam::cam_plugins"

  iis_app "CAM" do
  	path "/Cam"
  	application_pool app_pool
  	physical_path install_dir
  	action :add
  end

  iis_config auth_cmd do
  	action :config
  end

end
