require 'redmine'

%w{ controllers views models helpers metal}.each do |dir| 
	path = File.join(File.dirname(__FILE__), 'app', dir)  
	$LOAD_PATH << path
	ActiveSupport::Dependencies.load_paths << path 
	ActiveSupport::Dependencies.load_once_paths.delete(path) 
end 


Redmine::Plugin.register :redmine_weekly_time do
  name 'Redmine Weekly Time plugin'
  author 'Dave Birch'
  description 'Makes entering time for a week easier'
  version '0.0.1'
  menu :top_menu, :weekly_time, { :controller => 'weekly_time_entries', :action => 'index'}, :caption => 'Timesheet (Weekly view)'
end
