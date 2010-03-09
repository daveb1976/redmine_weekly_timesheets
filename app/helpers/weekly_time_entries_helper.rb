module WeeklyTimeEntriesHelper
  def hours_today(entries, day, activity = nil)
    if activity
      entries.select{ |e| e.spent_on == day and e.activity == activity }.sum(&:hours)
    else
      entries.select{ |e| e.spent_on == day }.sum(&:hours)
    end
  end
end
