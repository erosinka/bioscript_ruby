module ApplicationHelper
    def display_date(c)
    n = Time.now
    html = "" #<table class='display_date'><tr><td class='day'>"
    if n.day == c.day and n.month == c.month and n.year == c.year
      html += "Today"
    #elsif n.day == c.day + 1 and n.month == c.month and n.year == c.year
    #  html += "Yesterday"
    else
      html += "#{c.year}-#{"0" if c.month < 10}#{c.month}-#{"0" if c.day < 10}#{c.day}"
    end
    html += " at #{"0" if c.hour < 10}#{c.hour}:#{"0" if c.min < 10}#{c.min}" #</td></tr></table>"
    end
end
