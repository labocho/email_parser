# EmailParser

Ruby gem for parsing or validating email address.
Parsing email address based on RFC5321 and RFC1035. But some violations are allowed by option.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'email_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install email_parser


## Usage


```ruby
EmailParser.parse("test@example.com")
# => [:mailbox, [:local_part, [:dot_string, [:atom, "test"]]], "@", [:domain, [:subdomain, [:label, "example"], [:dot, "."], [:label, "com"]]]]

EmailParser.valid?("test@example.com") # => true

EmailParser.valid?("test.@example.com") # => false
EmailParser.valid?("test.@example.com", allow_local_end_with_dot: true) # => true
```

## Parser options

- `allow_address_literal: true` allows `a@[127.0.0.1]` etc. (default: `false`)
- `allow_dot_sequence_in_local: true` allows `a..b@example.com` etc. (default: `false`)
- `allow_local_begin_with_dot: true` allows `.a@example.com` etc. (default: `false`)
- `allow_local_end_with_dot: true` allows `a.@example.com` etc. (default: `false`)


## Use as ActiveModel validator

```ruby
gem "email_parser", require: "email_parser/validator"
```

```ruby
class Person
  # All parser options and :allow_nil option are accepted.
  validates :email, email: {allow_nil: true, allow_local_end_with_dot: true}
end
```

You can set default parser options globally.

```ruby
EmailValidator.default_parser_options.merge!(
  allow_local_end_with_dot: true,
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/labocho/email_parser.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
