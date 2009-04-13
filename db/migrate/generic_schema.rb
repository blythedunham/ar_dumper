ActiveRecord::Schema.define do


  create_table :topics, :force=>true do |t|
    t.column :title, :string, :null=>false
    t.column :author_name, :string
    t.column :author_email_address, :string
    t.column :written_on, :datetime
    t.column :bonus_time, :time
    t.column :last_read, :datetime
    t.column :content, :text
    t.column :approved, :boolean, :default=>'1'
    t.column :replies_count, :integer
    t.column :parent_id, :integer
    t.column :type, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end


  create_table :books, :force=>true do |t|
    t.column :title, :string, :null=>false
    t.column :publisher, :string, :null=>false, :default => 'Default Publisher'
    t.column :author_name, :string, :null=>false
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :topic_id, :integer
    t.column :for_sale, :boolean, :default => true
  end

end
