  module RedmineEvm
  module Patches

    module EarnedValuePatch

      def self.included(base) # :nodoc:

        base.extend(ClassMethods)

        base.send(:include, EarnedValueInstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development  
        end

      end
    end

    module ClassMethods
      
    end

    module EarnedValueInstanceMethods

      def earned_value
        self.instance_of?(Project) ? issues = self.issues : issues = fixed_issues

        sum_earned_value = 0
        issues.each do |issue|
          unless issue.estimated_hours.nil?
            sum_earned_value += issue.estimated_hours * (issue.done_ratio / 100.0)
          end
        end
        sum_earned_value
      end

      def get_issues key
        if self.instance_of?(Project) 
          Issue.find_by_sql(['SELECT i.done_ratio, i.estimated_hours  FROM redmine.issues i join redmine.time_entries t on( i.id = t.issue_id) where i.project_id = :id group by i.id having max(spent_on) = :key;', id: id, key: key])
        else
          Issue.find_by_sql(['SELECT i.done_ratio, i.estimated_hours  FROM redmine.issues i join redmine.time_entries t on( i.id = t.issue_id) where i.fixed_version_id = :id group by i.id having max(spent_on) = :key;', id: id, key: key])
        end
      end

      def earned_value_by_week
        done_ratio_by_weeks = {}
        done_ratio = 0
        earned_value = 0

        (get_start_date.to_date..end_date.to_date).each do |key| 
          issues = get_issues key
          unless issues.nil?
            issues.each do |issue|
              unless issue.estimated_hours.nil?
                done_ratio = issue.done_ratio / 100.0
                earned_value += issue.estimated_hours * done_ratio  
              end  
            end
          end
          
          done_ratio_by_weeks[key.beginning_of_week] = earned_value
        end
        done_ratio_by_weeks
      end    
      
    end

  end
end

unless Project.included_modules.include?(RedmineEvm::Patches::EarnedValuePatch)
  Project.send(:include, RedmineEvm::Patches::EarnedValuePatch)
end
unless Version.included_modules.include?(RedmineEvm::Patches::EarnedValuePatch)
  Version.send(:include, RedmineEvm::Patches::EarnedValuePatch)
end