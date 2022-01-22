# MySQL Notes

## Resources
<details>
<summary>Click to expand</summary>

- [High Performance MySQL, 3rd Edition](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/)
</details>
<br />

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
