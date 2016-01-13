if node['sync-ftp-folders']['status'] == 'Y'
  directory "/home/#{node['share-server']['ftp']['username']}/backup" do
    owner "#{node['share-server']['ftp']['username']}"
    group "#{node['share-server']['ftp']['username']}"
    mode '0744'
    action :create
  end
  
  node['sync-ftp-folders']['remote-credentials'].each_index do |i|
    directory "/home/#{node['share-server']['ftp']['username']}/backup/#{node['sync-ftp-folders']['remote-credentials'][i]['host']}" do
      owner "#{node['share-server']['ftp']['username']}"
      group "#{node['share-server']['ftp']['username']}"
      mode '0744'
      action :create
    end
    
    execute "echo '0 3 * * *   #{node['share-server']['ftp']['username']}   lftp -p #{node['sync-ftp-folders']['remote-credentials'][i]['port']} -u #{node['sync-ftp-folders']['remote-credentials'][i]['username']},#{node['sync-ftp-folders']['remote-credentials'][i]['password']} -e \"set ssl-allow true && set ssl:verify-certificate false && mirror . /home/#{node['share-server']['ftp']['username']}/backup/#{node['sync-ftp-folders']['remote-credentials'][i]['host']} && quit\" #{node['sync-ftp-folders']['remote-credentials'][i]['host']}' >> /etc/cron.d/ftp-sync"
  end

  # Add sync-service credentials to info-file
  execute "printf '\n\n%s\n%s' '[Syncing-ftp-folders]' 'Enabled.' >> /tmp/credentials"
end

if node['backup-shared-folder']['status'] == 'Y'
  execute "echo '0 4 * * 6   duplicity   duplicity full --no-encryption /home/#{node['share-server']['ftp']['username']}/backup file:///home/duplicity' >> /etc/cron.d/duplicity"
  execute "echo '0 5 * * *   duplicity   duplicity incremental --no-encryption /home/#{node['share-server']['ftp']['username']}/backup file:///home/duplicity' >> /etc/cron.d/duplicity"
  execute "echo '0 6 * * 6   duplicity   duplicity remove-all-but-n-full 3 --force file:///home/duplicity' >> /etc/cron.d/duplicity"
  
  # Add duplicity credentials to info-file
  execute "printf '\n\n%s\n%s' '[Duplicity]' 'Enabled.' >> /tmp/credentials"
end
  
