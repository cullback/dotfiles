# LLM Guide

## Styleguide

- prefer short functions under 16 lines of code
- prefer pure functions that are easy to test
- prefer functions that do one simple thing
- move side effects into their own function that only perform that one operation
- don't create unnecessary classes. only for bundles of behavior and state
- push ifs up and fors down
- avoid inheritance

## Commit messages

- Use imperative form
- Capitalize the first letter
- communicate what the change does without having to look at the source code
- Should start with verb such as Add, Fix, Improve, etc.

## Rust

- avoid `as` conversions

## Python

- use python 3.9 features
- annotate functions with type hints
- use `class Data(typing.NamedTuple)` for records
- prefer asserts over exceptions for error handling
- use lowercase variants for type hints: `list, tuple, dict`
- `__name__ == "__main__"` should call out to main or test function
- use uv for dependency and project management
- use pathlib for file system operations

## Markdown

- make sure there's a newline after headers

