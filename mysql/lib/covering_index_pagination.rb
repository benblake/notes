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

# Non covering index table
schema_setup_sql = <<-SQL
  DROP TABLE IF EXISTS `test_table`;
  CREATE TABLE `test_table` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `first_name` varchar(255) DEFAULT NULL,
    `last_name` varchar(255) DEFAULT NULL,
    `sex` varchar(1) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sex` (`sex`)
  );
SQL
client.query(schema_setup_sql);
while client.next_result; end;

# Insert the same data
100_000.times do |i|
  sex = i % 2 == 0 ? "M" : "F"
  first_name = client.escape(Faker::Name.first_name)
  last_name = client.escape(Faker::Name.last_name)
  client.query("
    INSERT INTO `test_table` (`first_name`, `last_name`, `sex`) VALUES ('#{first_name}', '#{last_name}', '#{sex}');
  ")
end

# Compare
Benchmark.ips do |x|
  x.report "with deferred join" do
    client.query("
      SELECT * FROM test_table INNER JOIN (
        SELECT id, sex FROM test_table
        WHERE sex = 'M'
        ORDER BY id DESC
        LIMIT 49900, 50
      ) AS x USING(id);
    ");
  end

  x.report "without deferred join" do
    client.query("
      SELECT * FROM test_table
      WHERE sex = 'M'
      ORDER BY id DESC
      LIMIT 49900, 50;
    ");
  end

  x.compare!
end

# Results:
# Warming up --------------------------------------
#   with deferred join     5.000  i/100ms
# without deferred join
#                          1.000  i/100ms
# Calculating -------------------------------------
#   with deferred join     55.364  (± 7.2%) i/s -    280.000  in   5.082580s
# without deferred join
#                          15.207  (± 6.6%) i/s -     76.000  in   5.006119s

# Comparison:
#   with deferred join:       55.4 i/s
# without deferred join:       15.2 i/s - 3.64x  (± 0.00) slower
