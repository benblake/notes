This is where I will be adding MySQL notes.

I will also be (hopefully) doing some test/benchmarks to refer from the notes. To do this I made a simple Docker compose setup with a MySQL container and a Ruby container. Right now to run the container you can use
```
$ docker-compose up --build
```
Then check the containers running using `docker ps`. You can connect to the Ruby (or MySQL) container using
```
$ docker exec -it <container_id> sh
```

Right now the only ruby file just creates a table, inserts some data, then queries it. You can run it from the shell with
```
$ ruby lib/test.rb
```


After adding a new dependency the Gemfile.lock can be regenerated using
```
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:3.0 bundle install
```
This can probably(?) be done from inside the container and just running `bundle install`, since the main folder is volumed.
