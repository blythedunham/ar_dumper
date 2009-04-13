class Book < ActiveRecord::Base
  belongs_to :topic

  def topic_name
    self.topic ? self.topic.title : "NO TOPIC"
  end
  
end
