require "active_model"
require "email_parser"

class EmailValidator < ActiveModel::EachValidator
  class << self
    attr_accessor :default_parser_options
  end

  self.default_parser_options = {}

  def initialize(*_args)
    super
    parser_options = options.each_with_object({}) do |(k, v), h|
      h[k] = v if EmailParser::OPTIONS.include?(k)
    end
    @parser = EmailParser.new(**self.class.default_parser_options.merge(parser_options))
  end

  def validate_each(record, attribute, value)
    if value.nil?
      return if options[:allow_nil]

      record.errors.add(attribute, :blank)
      return
    end

    return if @parser.valid?(value)

    record.errors.add(attribute, :invalid)
  end
end
