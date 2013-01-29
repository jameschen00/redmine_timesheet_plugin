#require_dependency 'users_helper'
module RedmineTimesheetPlugin
  module UsersHelperPatch
    unloadable
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
      end
    end

    module InstanceMethods

        # Wrapper for User#allowed_to? that doesn't reject archived projects
        # automatically
        def allowed_to_on_single_potentially_archived_project?(action, context, options={})
          if Setting.plugin_redmine_timesheet_plugin['project_status'] == 'all' && context && context.is_a?(Project) && !context.active?
            # Duplicated from User#allowed_to? but without the archived project guard
            # No action allowed on disabled modules
            return false unless context.allows_to?(action)
            # Admin users are authorized for anything else
            return true if admin?
      
            roles = roles_for_project_with_potentially_archived_project(context)
            return false unless roles
            roles.detect {|role| (context.is_public? || role.member?) && role.allowed_to?(action)}
            
          else
            allowed_to?(action, context, options)
          end
        end
        
        def roles_for_project_with_potentially_archived_project(project)
            roles = []
          if logged?
            # Find project membership
            # ED: use members because membership is only for unarchived projects
            membership = members.detect {|m| m.project_id == project.id}
            if membership
              roles = membership.roles
            else
              @role_non_member ||= Role.non_member
              roles << @role_non_member
            end
          else
            @role_anonymous ||= Role.anonymous
            roles << @role_anonymous
          end
          roles
        end
    end
  end
end

#ActionDispatch::Callbacks.to_prepare do
  #User.send(:include, AdvancedRoadmap::UserPatch)
#  User.send(:include, TimesheetPlugin::Patches::UserPatch)
#end
# now we should include this module in ApplicationHelper module
#unless UsersHelper.included_modules.include? TimesheetPlugin::Patches::UsersHelperPatch
#    UsersHelper.send(:include, TimesheetPlugin::Patches::UsersHelperPatch)
#end
