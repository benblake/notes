require "pry"
require "mysql2"
require "faker"
require "benchmark/ips"

client = Mysql2::Client.new(
  host: ENV["MYSQL_HOST"],
  username: ENV["MYSQL_USERNAME"],
  password: ENV["MYSQL_PWD"],
  database: ENV["MYSQL_DB"],
  flags: Mysql2::Client::MULTI_STATEMENTS
)

# Will probably want to make this generic enough to read in a schema definition file instead
schema_setup_sql = <<-SQL
  DROP TABLE IF EXISTS `test_table`;
  CREATE TABLE `test_table` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `first_name` varchar(255) DEFAULT NULL,
    `last_name` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_first_name` (`first_name`)
  );
SQL
client.query(schema_setup_sql);
while client.next_result; end; # this is needed to execute successive commands

10_000.times do |i|
  first_name = i % 100 == 0 ? "Ben" : client.escape(Faker::Name.first_name)
  last_name =  i % 100 == 0 ? "Blake" : client.escape(Faker::Name.last_name)
  client.query("
    INSERT INTO `test_table` (
      `first_name`,
      `last_name`
    )
    VALUES (
      '#{first_name}',
      '#{last_name}'
    );
  ")
end

# Basic select with/without index
Benchmark.ips do |x|
  x.report "with index" do
    client.query("SELECT count(*) FROM test_table WHERE first_name = 'Ben';");
  end

  x.report "without index" do
    client.query("SELECT count(*) FROM test_table WHERE last_name = 'Blake';");
  end

  x.compare!
end

# Basic select with/without covering index
Benchmark.ips do |x|
  x.report "with covering index" do
    client.query("SELECT id, first_name FROM test_table WHERE first_name = 'Ben';");
  end

  x.report "without covering index" do
    client.query("SELECT * FROM test_table WHERE first_name = 'Ben';");
  end

  x.compare!
end
