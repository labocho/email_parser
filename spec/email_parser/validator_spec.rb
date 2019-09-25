require "email_parser/validator"

RSpec.describe EmailValidator do
  let(:person) {
    Person.new(email: "valid@example.com")
  }

  before do
    class Person
      include ActiveModel::Validations
      attr_accessor :email

      def initialize(attributes = {})
        attributes.each do |k, v|
          send("#{k}=", v)
        end
      end
    end
  end

  after do
    Object.send(:remove_const, :Person)
  end

  context "no options" do
    before do
      Person.class_eval do
        validates :email, email: true
      end
    end

    it "validates email" do
      expect(person).to be_valid

      person.email = "invalid.@example.com"
      expect(person).not_to be_valid
      expect(person.errors[:email]).to eq ["is invalid"]

      person.email = nil
      expect(person).not_to be_valid
      expect(person.errors[:email]).to eq ["can't be blank"]
    end
  end

  context "allow_nil" do
    before do
      Person.class_eval do
        validates :email, email: {allow_nil: true}
      end
    end

    it "validates email" do
      expect(person).to be_valid

      person.email = "invalid.@example.com"
      expect(person).not_to be_valid
      expect(person.errors[:email]).to eq ["is invalid"]

      person.email = nil
      expect(person).to be_valid
    end
  end

  context "if" do
    before do
      Person.class_eval do
        attr_accessor :sms
        validates :email, email: {if: -> { sms.nil? }}
      end
    end

    it "validates email" do
      expect(person).to be_valid

      person.email = "invalid.@example.com"
      expect(person).not_to be_valid

      person.sms = "00000000000"
      expect(person).to be_valid
    end
  end

  context "parser option specified" do
    before do
      Person.class_eval do
        validates :email, email: {allow_local_end_with_dot: true}
      end
    end

    it "validates email" do
      expect(person).to be_valid

      person.email = "invalid.@example.com"
      expect(person).to be_valid

      person.email = ".invalid@example.com"
      expect(person).not_to be_valid
      expect(person.errors[:email]).to eq ["is invalid"]
    end
  end

  context "default parser option specified" do
    before do
      EmailValidator.default_parser_options[:allow_local_end_with_dot] = true

      Person.class_eval do
        validates :email, email: {allow_local_end_with_dot: true}
      end
    end

    after do
      EmailValidator.default_parser_options.delete(:allow_local_end_with_dot)
    end

    it "validates email" do
      expect(person).to be_valid

      person.email = "invalid.@example.com"
      expect(person).to be_valid

      person.email = ".invalid@example.com"
      expect(person).not_to be_valid
      expect(person.errors[:email]).to eq ["is invalid"]
    end
  end
end
