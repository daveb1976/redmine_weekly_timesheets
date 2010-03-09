class WeeklyTimeEntriesController < ApplicationController

  before_filter :dates, :current_user

  def index
    puts params[:year].to_i
    @time_entries = TimeEntry.find(:all, :conditions => {:user_id => @current_user.id, :tweek => @week})
    @day_range = @week_start.to_date..@week_end.to_date
    @grouped_entries = @time_entries.group_by{ |e| e.project  }
  end

  def show
  end

  def update
    messages = []
    params[:project_id].each do |project_id, activities|
      activities[:activity_id].each do |activity_id, hours|
        time_entries = TimeEntry.find(:all, :conditions => {:activity_id => activity_id, :tyear => @year, :tweek => @week, :project_id => project_id, :user_id => @current_user.id})
        activity = TimeEntryActivity.find(activity_id)
        # Only log hours that aren't already included in the timesheet
        hours_to_log = hours.select do |day, hrs|
          time_entries.select{|e| e.spent_on.to_date == day.to_date and e.hours.to_f == hrs.to_f}.empty?
        end
        
        hours_to_log.each do |day, hours|
          already_logged = time_entries.select{|e| e.spent_on.to_date == day.to_date and e.issue.blank?}
          if !already_logged.empty?
            delta = hours.to_f - already_logged.sum(&:hours).to_f
            if delta > 0
#             We're adding hours to the existing timesheet entries.  Just add to the first one
              messages << "Added #{delta} hours of #{activity.name} to #{day}"
              already_logged.first.update_attributes(:hours =>  already_logged.first.hours + delta)
            elsif delta == 0
              true
            else
#             We're subtracting hours.  We need to subtract from each time log entry until they're gone
              already_logged.inject(delta) do |delta, time_entry|
                if delta < time_entry.hours.to_f
                  messages << "Subtracted #{delta.abs} hours of #{activity.name} from #{time_entry.spent_on}"
                  time_entry.hours += delta
                  delta = 0
                  time_entry.save!
                else
                  delta += time_entry.hours # += because delta is a negative number in this case
                  messages << "Deleted timesheet entry for #{activity.name} #{time_entry.spent_on}"
                  time_entry.destroy
                end
                delta
              end
            end
#         If no time entries exist for the day then create one         
          else
            if hours.to_f > 0
              TimeEntry.create!({:user => @current_user,
                   :project => Project.find(project_id),
                   :activity => TimeEntryActivity.find(activity_id),
                   :hours => hours,
                   :spent_on => day.to_date
                 }) 
              messages << "Created timesheet entry for #{hours} hours of #{activity.name} on #{day}"
            end
          end
        end
      end
    end
    flash[:notice] = messages.join("<br/>") unless messages.empty?
    redirect_to :action => "index", :year => @year, :week_num => @week
  end

  def destroy
  end

  protected

  def dates
    @year = (params[:year] || DateTime.now.year).to_i
    @week = (params[:week_num] || DateTime.now.cweek).to_i
    @week_start = DateTime.commercial(y=@year, w=@week).beginning_of_week
    @week_end = DateTime.commercial(y=@year, w=@week).end_of_week
  end

  def current_user
    @current_user = User.current
  end
end
