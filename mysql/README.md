# MySQL Notes

## Resources
- [High Performance MySQL, 3rd Edition](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/)

## Basics
- Page size? What is a page?

## Benchmarks
<details>
<summary>Click to expand</summary>

This set of notes includes some benchmarking done with pretty simple Ruby scripts within this directory. These becnhmarks are built with a simple Docker compose setup with a MySQL container and a Ruby container. To run the containers you can use
```
$ docker-compose up --build
```
To check the running containers use `docker ps`. You can connect to the Ruby (or MySQL) container using
```
$ docker exec -it <container_id> sh
```
The benchmarks can be run from the shell in the Ruby container. For example just run.
```
$ ruby lib/test.rb
```

Note in the Dockerfile the `Gemfile.lock` is copied. To add a dependency and regenrate the Dockerfile you can use
```
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:3.0 bundle install
```
Alternatively, you can just run `bundle install` from shell in the container, since the main folder if volumed.
</details>

<br />

## Indexes
<details>
<summary>Click to expand</summary>

Most of these notes on indexes will only refer to the InnoDB storage engine and its B-Tree indexes, since they are by far the most common I have worked with.

You can always check what indexes a table has, and what their types are, using the command:
```sql
mysql> show indexes from <table_name>;
```
which will show results like the following:
```sql
mysql> show indexes from sample_table;
+--------------+------------+----------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table        | Non_unique | Key_name       | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+--------------+------------+----------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| sample_table |          0 | PRIMARY        |            1 | id          | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     | NULL       |
| sample_table |          1 | idx_first_name |            1 | first_name  | A         |           0 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
| sample_table |          1 | idx_full_name  |            1 | first_name  | A         |           0 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
| sample_table |          1 | idx_full_name  |            2 | last_name   | A         |           0 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+--------------+------------+----------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
4 rows in set (0.01 sec)
```
This show the indexes, their types, the columns that they are comprised of, and the order of the columns in the index. It also shows other info like the cardinality, nullability, etc.

### What is an index?
We have all heard a database index is like and index in a book - it makes it faster to look up a row matching a certain condition. But how exactly does this work?

Simply, and index is a data structure that a storage engine uses to find rows when a query condition is matched. But what is the data structure, and how does it actually find the matches quickly?

### B-Tree index basics
A B-Tree is a self-balancing n-ary tree data structure. The key aspect of a B-Tree is that the entries are _sorted_ based on the key value. Each node page stores upper and lower bounds of the values in its child nodes. When looking for a match the tree can be traversed based on comparison of the key with the upper and lower bounds of child nodes that are stored in the current node. InnoDB actually uses a B+Tree - which add pointers between sibling node pages. The general structure is
https://app.diagrams.net/#G12kP4iTn-pnYWMTFYJI59yygFiNBdhivk

The leaf page's data has a reference to the actual data for that row. These types of references differ between storage engines, but for InnoDB the reference is just a store of the row's primary key. Looking up the entire row's data then requires a query into the primary key's index, which stores the data for all the rows.

The keys stored for the index are the index's columns _in order_. In the example table above there is a compound index `idx_full_name` on the columns `(first_name, last_name)`. The index stores this data in the order of the columns - so first sorted by `first_name`, then within the same `first_name` it is sorted by `last_name`.
- This means that for a query to use an index the query must include the columns from the start of the index, and other columns in the order they exist in the index. In the above example a query of `select * from sample_table where last_name = "Blake";` will not be able to use this index.

This make B-Tree indexes good a some types of queries:
- Matching the full value - all an index's columns included in the query.
- Matching the columns in order - doesn't need to be all the columns, but they need to be in the order of the index's definition.
- Matching prefix on the first column - for `like` queries.
- Range of values based on the colums in the index.
- B-Tree indexes also help with ordering, but have to be by all the same criteria above of which columns are included in the order.

### Index column ordering
Column order in an index is very important. The general advice is to order your columns by those that are most selective - those that eliminate the most rows from the result. This is good when you only need to optimize the `where` clause of your query, but may not be optimal solution if you also want your index to optimize for sorting and/or grouping.

### Clustered indexes
Every InnoDB table has a [clustered index](https://dev.mysql.com/doc/refman/5.7/en/innodb-index-types.html). If you define a primary key then that is the clustered index. This index is special in that it stores the values of the entire row on its leaf pages - it is the main data storage of the table.

A secondeary index (all other indexes) store a reference to the row data by storing the primary key on the lef pages of its index. This means that a lot of queries will have to look through two indexes to find the row data requested.

For example, consider the table:
```sql
CREATE TABLE sample_table (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  first_name varchar(255) DEFAULT NULL,
  last_name varchar(255) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_first_name (first_name)
)
```
and the query
```sql
SELECT * FROM sample_table WHERE first_name = "Ben";
```
This query will generally do the following:
- Execute an index lookup against the secondary index on `first_name`. This will return a set of primary keys.
- The query request to `SELECT *` - so it needs to return the full row data of `id`, `first_name`, and `last_name`. From the preceding index lookup it has the values of `id` and `first_name` - but not `last_name`.
- Execute another index lookup against the clustered index with the `id` values returned from the first lookup. This will get all the row data requested, including `last_name`.

Note that the queries
```sql
SELECT first_name FROM sample_table WHERE first_name = "Ben";
```
and
```sql
SELECT id, first_name FROM sample_table WHERE first_name = "Ben";
```
would _not_ need to perform the second lookup against the clustered index because all the date requested would be returned from the first index lookup. In these cases, the secondary index is a **covering index** for the query, and it much preferable and quicker, since it is generally half the work.

To test this out you can run the `covering_index.rb` benchmark script. When I ran this against 100,000 records it gave following results which showed the covering index to be almost twice as fast than without the covering index.

```
# ruby lib/covering_index.rb
Warming up --------------------------------------
 with covering index   110.000  i/100ms
without covering index
                        55.000  i/100ms
Calculating -------------------------------------
 with covering index      1.072k (± 2.9%) i/s -      5.390k in   5.034540s
without covering index
                        557.285  (± 7.5%) i/s -      2.805k in   5.070002s

Comparison:
 with covering index:     1071.6 i/s
without covering index:      557.3 i/s - 1.92x  (± 0.00) slower
```
<!-- ## Query optimization -->
<!-- ## Using `EXPLAIN` -->
<!-- ## Transactions -->
<!-- ## Locks -->
<!-- <br /> -->
</details>
