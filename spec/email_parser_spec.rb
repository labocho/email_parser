RSpec.describe EmailParser do
  it "has a version number" do
    expect(EmailParser::VERSION).not_to be nil
  end

  describe ".valid?" do
    [
      [%(a@b), true],
      [%(a.b.c@b), true],
      [%(abcABC012!#$%&'*+-/=?^_`{|}~@b), true],
      [%(()@b), false],
      [%("()"@b), true],
      [%("\\a"@b), true],
      [%(a@b.c), true],
      [%(a@0b), false],
      [%(a@b0), true],
      [%(a@b0), true],
      [%(a@bb-cc), true],
      [%(a@b-), false],
      [%(a@b-.c), false],
      [%(a..b@b), false],
      [%(a..b@b), true, allow_dot_sequence_in_local: true],
      [%(.a@b), false],
      [%(.a@b), true, allow_local_begin_with_dot: true],
      [%(a.@b), false],
      [%(a.@b), true, allow_local_end_with_dot: true],
    ].each do |(email, validity, options)|
      context email do
        subject { EmailParser.valid?(email, options || {}) }
        it { should eq validity }
      end
    end
  end
end
