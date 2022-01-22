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

# Covering index table
schema_setup_sql = <<-SQL
  DROP TABLE IF EXISTS `covering_index_table`;
  CREATE TABLE `covering_index_table` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `first_name` varchar(255) DEFAULT NULL,
    `last_name` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_full_name` (`first_name`, `last_name`)
  );
SQL
client.query(schema_setup_sql);
while client.next_result; end;

# Non covering index table
schema_setup_sql = <<-SQL
  DROP TABLE IF EXISTS `non_covering_index_table`;
  CREATE TABLE `non_covering_index_table` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `first_name` varchar(255) DEFAULT NULL,
    `last_name` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_first_name` (`first_name`)
  );
SQL
client.query(schema_setup_sql);
while client.next_result; end;

# Insert the same data
100_000.times do |i|
  first_name = i % 100 == 0 ? "Ben" : client.escape(Faker::Name.first_name)
  last_name =  i % 100 == 0 ? "Blake" : client.escape(Faker::Name.last_name)
  client.query("
    INSERT INTO `covering_index_table` (`first_name`, `last_name`) VALUES ('#{first_name}', '#{last_name}');
  ")
  client.query("
    INSERT INTO `non_covering_index_table` (`first_name`, `last_name`) VALUES ('#{first_name}', '#{last_name}');
  ")
end

# Compare
Benchmark.ips do |x|
  x.report "with covering index" do
    client.query("SELECT * FROM covering_index_table WHERE first_name = 'Ben';");
  end

  x.report "without covering index" do
    client.query("SELECT * FROM non_covering_index_table WHERE first_name = 'Ben';");
  end

  x.compare!
end

# Results:
# Warming up --------------------------------------
#  with covering index   110.000  i/100ms
# without covering index
#                         55.000  i/100ms
# Calculating -------------------------------------
#  with covering index      1.072k (± 2.9%) i/s -      5.390k in   5.034540s
# without covering index
#                         557.285  (± 7.5%) i/s -      2.805k in   5.070002s

# Comparison:
#  with covering index:     1071.6 i/s
# without covering index:      557.3 i/s - 1.92x  (± 0.00) slower
