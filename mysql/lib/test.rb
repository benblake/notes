require "pry"
require "mysql2"

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
    `name` varchar(255) DEFAULT NULL,
    `address` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  );
SQL
client.query(schema_setup_sql);
while client.next_result; end; # this is needed to execute successive commands

client.query("INSERT INTO `test_table` (`name`, `address`) VALUES ('ben', '1234 main st.');")
client.query("INSERT INTO `test_table` (`name`, `address`) VALUES ('levi', '567 yonge st.');")
client.query("INSERT INTO `test_table` (`name`, `address`) VALUES ('heidi', '234 queen st.');")
client.query("INSERT INTO `test_table` (`name`, `address`) VALUES ('logan', '98 king st.');")
results = client.query("SELECT * FROM test_table;");
results.each { |r| puts r }
