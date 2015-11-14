# Specinfra Docker LXC Backend
[![Gem Version](http://img.shields.io/gem/v/specinfra-backend-docker_lxc.svg?style=flat)](http://badge.fury.io/rb/specinfra-backend-docker_lxc)
[![Dependency Status](http://img.shields.io/gemnasium/zuazo/specinfra-backend-docker_lxc.svg?style=flat)](https://gemnasium.com/zuazo/specinfra-backend-docker_lxc)
[![Code Climate](http://img.shields.io/codeclimate/github/zuazo/specinfra-backend-docker_lxc.svg?style=flat)](https://codeclimate.com/github/zuazo/specinfra-backend-docker_lxc)
[![Circle CI](https://circleci.com/gh/zuazo/specinfra-backend-docker_lxc/tree/master.svg?style=shield)](https://circleci.com/gh/zuazo/specinfra-backend-docker_lxc/tree/master)
[![Travis CI](http://img.shields.io/travis/zuazo/specinfra-backend-docker_lxc/0.1.0.svg?style=flat)](https://travis-ci.org/zuazo/specinfra-backend-docker_lxc)
[![Coverage Status](http://img.shields.io/coveralls/zuazo/specinfra-backend-docker_lxc/0.1.0.svg?style=flat)](https://coveralls.io/r/zuazo/specinfra-backend-docker_lxc?branch=0.1.0)
[![Inline docs](http://inch-ci.org/github/zuazo/specinfra-backend-docker_lxc.svg?branch=master&style=flat)](http://inch-ci.org/github/zuazo/specinfra-backend-docker_lxc)

[Serverspec](http://serverspec.org/)/[Specinfra](https://github.com/mizzy/specinfra) backend for Docker LXC execution driver.

## Requirements

* Recommended Docker `1.7.0` or higher.
* `sudo` installed (not in the container).
* `lxc-attach` binary installed (included in the `lxc` package).

## Installation

Add this line to your application's Gemfile:

```ruby
# Gemfile

gem 'specinfra-backend-docker_lxc', '~> 0.1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install specinfra-backend-docker_lxc

## Usage

```ruby
require 'serverspec'
require 'specinfra/backend/docker_lxc'

set :docker_image, ENV['DOCKER_IMAGE_ID']
set :backend, :docker_lxc

describe 'Dockerfile run' do
  describe service('httpd') do
    it { should be_enabled }
    it { should be_running }
  end
end
```

## Configuration

Uses the following `Specinfra` configuration options:

- `:sudo_options`: Sudo command argument list as string or as array.
- `:sudo_path`: Sudo binary directory.
- `:sudo_password`
- `:disable_sudo`: whether to disable Sudo (enabled by default).

For example:

```ruby
set :sudo_password, 'mBnriM8SKhRtIww7xgUi'
```

## Testing

See [TESTING.md](https://github.com/zuazo/specinfra-backend-docker_lxc/blob/master/TESTING.md).

## Contributing

Please do not hesitate to [open an issue](https://github.com/zuazo/specinfra-backend-docker_lxc/issues/new) with any questions or problems.

See [CONTRIBUTING.md](https://github.com/zuazo/specinfra-backend-docker_lxc/blob/master/CONTRIBUTING.md).

## TODO

See [TODO.md](https://github.com/zuazo/specinfra-backend-docker_lxc/blob/master/TODO.md).

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | [Xabier de Zuazo](https://github.com/zuazo) (<xabier@zuazo.org>)
| **Copyright:**       | Copyright (c) 2015 Xabier de Zuazo
| **License:**         | Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
