# Jac - just another configuration lib

[![Gem](https://img.shields.io/gem/v/jac.svg)](https://rubygems.org/gems/jac)
[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/vizor-games/jac.svg)](https://codeclimate.com/github/vizor-games/jac)
[![Code Climate](https://codeclimate.com/github/vizor-games/jac/badges/gpa.svg)](https://codeclimate.com/github/vizor-games/jac)
[![Build Status](https://travis-ci.org/vizor-games/jac.svg?branch=master)](https://travis-ci.org/vizor-games/jac)

## Installation and usage

To start using jac you need to add 

```ruby
gem 'jac', '0.0.2'
```

to your `Gemfile` and load configuration from default paths (`jac.yml`, `jac.user.yml`) relative to working dir:

```ruby
require 'jac'
profile = %w[any profile combination]
Jac::Configuration.load(profile) # => OpenStruct
```

or to load custom set of files:

```ruby
require 'jac'
profile = %w[any profile combination]
Jac::Configuration.load(profile, files: %w[example/config/base.yml example/config/custom.yml]) # => OpenStruct
```

## Features

Configuration is loaded from well formed YAML streams.
Each document expected to be key-value mapping where
keys a `profile` names and values is a profile content.
Profile itself is key-value mapping too. Except reserved
key names (i.e. `extends`) each key in profile is a
configuration field. For example following yaml document

```yml

foo:
  bar: 42
qoo:
  bar: 32

```

represents description of two profiles, `foo` and `qoo`,
where field `bar` is set to `42` and `32` respectively.

Profile can be constructed using combination of other profiles
for example having `debug` and `release` profiles for testing
and production. And having `remote` and `local` profiles for
building on local or remote machine. We cant get `debug,local`,
`debug,remote`, `release,local` and `release,remote` profiles.
Each of such profiles is a result of merging values of listed
profiles. When merging profile with another configuration
resolver overwrites existing fields. For example if `debug`
and `local` for some reason have same field. In profile
`debug,local` value from `debug` profile will be overwritten
with value from `local` profile.

### Extending profiles

One profile can `extend` another. Or any amount of other
profiles. To specify this one should use `extends` field
like that

```yml

base:
  application_name: my-awesome-app
  port: 80

version:
  version_name: 0.0.0
  version_code: 42

debug:
  extends: [base, version]
  port: 9292
```

In this example `debug` will receive following fields:

```yml
application_name: my-awesome-app  # from base profile
port: 9292                        # from debug profile
version_name: 0.0.0               # from version profile
version_code: 42                  # from version profile
```

### Merging multiple configuration files

Configuration can be loaded from multiple YAML documents.
Before resolve requested profile all described profiles
are merged down together. Having sequence of files like
`.application.yml`, `.application.user.yml` with following content

```yml
# .application.yml
base:
  user: deployer

debug:
  extends: base
  # ... other values
```

```yml
# .application.user.yml
base:
user: developer
```

We'll get `user` field overwritten with value from
`.application.user.yml`. And only after that construction
of resulting profile will begin (for example `debug`)

### String evaluation

Configuration resolver comes with powerful yet dangerous
feature: it allows evaluate strings as ruby expressions
like this:

```yml
foo:
  build_time: "#{Time.now}" # Will be evaluated at configuration resolving step
```

Configuration values are available to and can be referenced with `c`:

```yml
base:
  application_name: my-awesome-app
debug:
  extends: base
  server_name: "#{c.application_name}-debug"   # yields to my-awesome-app-debug
release:
  extends: base
  server_name: "#{c.application_name}-release" # yields to my-awesome-app-release
```

All strings evaluated **after** profile is constructed thus
you don't need to have declared values in current profile
but be ready to get `nil`.

### Merging values

By default if one value have multiple defenitions it will be overwritten by
topmost value. Except several cases where Jac handles value resolution
specialy

#### Merging hashes

Hashes inside profile are recurseively merged automatically. This rule works
for profile extensions and value redefenitions too.

Example:

```yml
base:
  servers:
    release: 'http://release.com'

debug:
  extends: base
  servers:                      # will contain {'debug' => 'https://debug.com', 'release' => 'https://release.com'}
    debug: 'http://debug.com'

```

#### Merging sets

Sets allowed to be merged with `nil`s and any instance of `Enumerable`.
Merge result is always new `Set` instance.

Example: 
```yml
release:
  extends:
    - no_rtti
    - no_debug
  flags: !set {} # empty set
no_rtti:
  flags:
    - '-fno-rtti'
no_debug:
  flags:
    - '-DNDEBUG'
```

Resulting profile will have `Set('-fno-rtti', '-DNDEBUG')` in `release profile`
## Generic profiles

Same result as shown above can be achieved with generic profiles. Generic profile
is a profile which name is regex (i.e. contained in `/.../`):

```yml
base:
  application_name: 'my-awesome-app'
/(release|debug)/: # Profile name is a regex, with single capture (1)
  extends: base
  server_name: "#{c.application_name}-#{c.captures[1]}"  # yields  my-awesome-app-release or  my-awesome-app-debug
```

If profile name matches multiple generic profiles it not defined
which profile will be used.

>  If running on Ruby 2.4+ you can use named captures in generic profiles.
> Named captures will be stored in `c.named_captures` as `Hash`. 

## License

jac is licensed under the MIT licence. Please see the [LICENSE](LICENSE) for more information.
