require 'redmine'

# Taken from lib/redmine.rb
if RUBY_VERSION < '1.9'
  require 'faster_csv'
else
  require 'csv'
  FCSV = CSV
end

require File.dirname(__FILE__) + '/lib/user_patch'
require File.dirname(__FILE__) + '/lib/timesheet_helper'
to_prepare = Proc.new do
  unless ActionView::Base.include?(RedmineTimesheetPlugin::Helper)
    ActionView::Base.send(:include, RedmineTimesheetPlugin::Helper)
  end
  unless User.include?(RedmineTimesheetPlugin::UsersHelperPatch)
    User.send(:include, RedmineTimesheetPlugin::UsersHelperPatch)
  end
end

if Redmine::VERSION::MAJOR >= 2
  Rails.configuration.to_prepare(&to_prepare)
else
  require 'dispatcher'
  Dispatcher.to_prepare(:redmine_timesheet_plugin, &to_prepare)
end


unless Redmine::Plugin.registered_plugins.keys.include?(:redmine_timesheet_plugin)
  Redmine::Plugin.register :redmine_timesheet_plugin do
    name 'Timesheet Plugin'
    author 'Eric Davis of Little Stream Software'
    description 'This is a Timesheet plugin for Redmine to show timelogs for all projects'
    url 'https://projects.littlestreamsoftware.com/projects/redmine-timesheet'
    author_url 'http://www.littlestreamsoftware.com'

    version '0.6.0'
    requires_redmine :version_or_higher => '0.9.0'
    
    settings(:default => {
               'list_size' => '5',
               'precision' => '2',
               'project_status' => 'active',
               'user_status' => 'active'
             }, :partial => 'settings/timesheet_settings')

    permission :see_project_timesheets, { }, :require => :member
    menu(:top_menu,
         :timesheet,
         {:controller => 'timesheet', :action => 'index'},
         :caption => :timesheet_title,
         :if => Proc.new {
           User.current.allowed_to?(:see_project_timesheets, nil, :global => true) ||
           User.current.allowed_to?(:view_time_entries, nil, :global => true) ||
           User.current.admin?
         })
  end
end

#if Rails::VERSION::MAJOR >= 3
#   ActionDispatch::Callbacks.to_prepare do
#     # use require_dependency if you plan to utilize development mode
#		 require File.dirname(__FILE__) + '/lib/user_patch'
#     UsersHelper.send(:include, TimesheetPlugin::Patches::UsersHelperPatch)
#   end
#else
#  Dispatcher.to_prepare BW_AssetHelpers::PLUGIN_NAME do
#    # use require_dependency if you plan to utilize development mode
#     #require File.dirname(__FILE__) + '/lib/user_patch'
#     #User.send(:include, TimesheetPlugin::Patches::UsersHelperPatch)
#     #require 'project_patch'
#     #require 'user_patch'
#  end
#end
