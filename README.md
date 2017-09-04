# MockCodeManager

This is a limited mock version of the [Puppet Code Manager REST API](https://docs.puppet.com/pe/latest/code_mgr_scripts.html).

It exists to allow Integration testing of software consuming this service without the need to stand-up a complete working Puppet Enterprise environment

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mock_code_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mock_code_manager

## Requirements

* Ruby 2.3+ (use [RVM](https://rvm.io/))
* openssl
* Access to `/tmp/mock_code_manager_ssl` for credential storage
* Hostname as reported by `hostname -f` **must** match the fqdn the service will be accessed from
* Port 8170 my be avaiable and reachable by the outside world

## Usage

### Simple

To generate all required SSL credentials and start a server on port 8170, run the command:

```shell
mock_code_manager
```

Note that this service will terminate when your login shell exits.  To prevent this, use `screen`, `nohup`, etc.

### Ruby

You can use the library as part of your ruby projects if you like.  Something like:

```ruby
Thread.start { MockCodeManager::WEBrick.run! }
```

In your `spec_helper.rb` along with a delay/test while the credentials are generated should be enough to get you started.

## API completeness

`/code-manager/v1/deploys`
* Authentication check
* Deploy all environments (`deploy-all`)
* Deploy selected environments (`environments`)

## Authentication
You must pass authentication tokens using the `X-Authentication` HTTP header.

The service will return an appropriate response based on the value or absence of this header:

### `PUPPET_DEPLOY_OK`
Proceed to service request

### Absent
`puppetlabs.rbac/user-unauthenticated`


### `PUPPET_DEPLOY_FAIL` (or any other value)
`puppetlabs.rbac/token-revoked` 

Note that the above responses are **always** expressed as JSON and always with status `200`.

## Contributing
PRs accepted :)
