require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:', verbosity: :quiet)

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(version: 1) do
    create_table :users
  end
end

class User < ActiveRecord::Base; end