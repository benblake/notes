# Rust Notes

Most of these notes are taken from the [Programming Rust book](https://www.oreilly.com/library/view/programming-rust-2nd/9781492052586/).

##  Basics

### Build tools
- `rustc` is the Rust compiler. Usually do not use this directly, but it gets run when compiling using `cargo`.
- `rustdoc` is Rust's documentation tool. It will create consistent documentation off correctly formatted comments in source code. It is usually invoked through `cargo` as well.
- `cargo` is a general purpose tool that handles compilation, package management, starting new projects, etc.

We can use `cargo new <project name>` to create a new Rust project. This will create:
- A `Cargo.toml` file that stores metadata and dependencies for the package. Cargo will handle the necessary dependency download and management for any dependencies listed in the `Cargo.toml` file. A starting toml file is:
  ```toml
  [package]
  name = "hello"
  version = "0.1.0"
  edition = "2021"

  # See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

  [dependencies]
  ```
- A `src` directory where all the Rust source code lives. It will create a `main.rs` file with the following content:
  ```rs
  fn main() {
      println!("Hello, world!");
  }
  ```
- All the necessary git files for a new project managed by git.

We can run the package with `cargo run`. This will use `rustc` to compile the program, will put the generated executable in the `target` directory, and then run the generated executable. To clean up all the generated files you can run `cargo clean`.

### Functions
Functions are declared with the `fn` keyword. An example function is 
```rs
fn gcd(mut n: u64, mut m: u64) -> u64 {}
```
Here we define a function named `gcd`, which takes arguments `n` and `m` of type `u64` - which is an unsigned 64-bit integer - and also has a return type of `u64`. Variables default to immutable in Rust, so declaring `n` and `m` as `mut` is needed to make them mutable in the body of the function.

Functions have `return` statements for their return values like may other languages, however they are not required if the function body ends with an expression that is not followed by a semi-colon. Return statements are generally used only for early returns of functions.

### Macros
Macros look similar to functions but end with a `!`. For example
```rs
assert!(n != 0 && m != 0)
```
calls the `assert!` macro to verify both `n` and `m` arguments are nonzero. If the assertion fails the program terminates with a panic. Assertion macros are always checked in all environments (debug & production). If you want a debug only assertion you can use `debug_assert!` instead.

### Variable declarations
Variables are declared with the `let` keyword. If the type cannot be infered the type must be included as part of the declaration. For example
```rs
let m: u64 = 4;
let t = m
```
would be valid - `m` must have its type declared, but `t`'s type can be inferred from `m`. You also need to include `mut` if you want a variable to be mutable, ie.
```rs
let mut m: u64 = 4;
```

### Unit tests
Rust supports writing unit tests as part of the language. A unit test is written as
```rs
#[test]
fn test_gcd() {
    assert_eq!(gcd(14, 15) 1)
}
```
Here the `#[test]` above the function declaration tells cargo to skip the function in normal compilation, but to be included and called if we run the `cargo test` command.

`#[test]` is an example of an attribute. Attributes are an open-ended system for marking functions and others declarations with additional information - similar to annotations in Java.

### Command line arguments
To get access to the command line args we must include the `std::env` module, which provides utilities for interacting with the execution environment.
```rs
use std::env`
```
This module has an `args` function which will give access to the command line args. For example, iterating over the command line args (excluding the first - which is the executable name) would look like
```rs
for arg in env::args().skip(1) {}
```

Command line arguments are stings, and to convert them to other types we need to use the standard library's `FromStr` trait. To do this we include the following
```rs
use std::str::FromStr;
```
This brings the trait into scope. A trait is a colleciton of methods that types can implement - in this case any type that implements the `FromStr` trait will have the `from_str` method. Integer types implement this trait, so we can use `u64::from_str()` to convert command line args to integers.

We can now iterate over the command line args, and push them to a `u64` vector with
```rs
let mut numbers = Vec::new();

for arg in env::args().skip(1) {
    numbers.push(u64::from_str(&arg)
                  .expect("error parsing argument"));
}
```

### `Result` values
A `Result` is a value that can have one of two variants: `Ok(v)` or `Err(e)`. These variants indicate that a process completed successfully (the `Ok` case) with resulting value `v`, or that it errored (the `Err` case) with error `e`. Rust does not have exceptions - so method calls that could fail will generally return a `Result` value, where the error case must be handled by the caller to be able to get access to the ok value.

In the above code `u64::from_str(&arg).expect("error parsing argument")` the `from_str` method is returning a `Result`, and `expect` is a method on the result that will panic (in this case with message `error parsing argument`) if it is the `Err` variant, and otherwise will return the value from the `Ok` variant.

### `Option` values
The `Option` type is an enumerated type defined as
```rs
enum Option<T> {
    None,
    Some(T),
}
```
This is similar to how you could have nullable types in other languages. Here Rust specifies the `None` and `Some(T)` variants of the enum so that if a function were to return this type than the caller would need to handle the `None` case appropriately if they want access to the value from the `Some` variant. This is how Rust handles getting rid of null pointer exceptions.

### `match`
Matching is an important concept in Rust. A lot of method calls will return an enum type - something like `Result` or `Option` above, and the calling function needs to handle the returned value's variants appropriately. This is where `match` comes in - it allows you to match on different variants of an enum (amongst other things) to conditionally handle the different possible values.

For example, consider trying to find an instance of a character `separator` in a string `s` - this can be done as
```rs
match s.find(separator) {
  None => None,
  Some(index) => {
    // do something with the index where separator was found
  }
}
```

Another common pattern is handling `Result` values, for example
```rs
let output = match File::create(filename) {
  Ok(f) => f,
  Err(e) => {
    return Err(e)
  }
};
```
This last example is actually so common there is a short form to handle it
```rs
let output = File::create(filename)?;
```



### Concurrency
Rust supports concurrency, and the way Rust handles ensuring programs are free from memory errors also ensure concurrent programs are free from race conditions. If your Rust program compiles you can be sure it will be free from race conditions - similar to how you can be sure it is free of memory issues.
