require 'rubygems'
require 'active_support'

class FiiwisMessage
  def initialize(message)
    @m = message
  end

  def tagged?
    @m["event"] == "message" &&
    @m["tags"].include?("fiiwis")
  end

  def valued?
    [1, 2, 3, 4, 5].include?(value)
  end

  def date
    Time.at(@m["sent"]/1000).strftime("%Y-%m-%d")
  end

  def week
    Time.at(@m["sent"]/1000).strftime("%Y/%U")
  end

  def user
    "User " + @m["user"]
  end
  
  def value
    values = @m["content"].scan(/\b[0-9]\b/)
    values.first.to_i if values.length == 1
  end
  
  def sanitized_message
    @m["content"].gsub(/\s/, " ")
  end
end


def write_csv(file, title_array, data_array)
  File.open(file, "w") do |f|
    f.puts(title_array.join("\t"))
    f.puts(data_array.map { |m| m.join("\t") }.join("\n"))
  end
end

messages = ActiveSupport::JSON.decode(File.read("messages.json"))
fiiwis_messages = messages.map { |m| FiiwisMessage.new(m) }.select(&:tagged?).select(&:valued?)
weeks = fiiwis_messages.map(&:week).uniq.sort
users = fiiwis_messages.map(&:user).uniq.sort
messages_by_weeks_and_users = fiiwis_messages.inject({}) { |hash, message|
  hash[message.week] ||= {}
  hash[message.week][message.user] = message
  hash
}

write_csv(
  "fiiwis_messages.csv",
  %w(date user fiiwis message),
  fiiwis_messages.map { |m|
    [m.date, m.user, m.value, m.sanitized_message]
  }
)

write_csv(
  "fiiwis_matrix.csv",
  ["week"] + users,
  weeks.map { |week| [week] + users.map { |user| messages_by_weeks_and_users[week][user].try(:value) } }
)