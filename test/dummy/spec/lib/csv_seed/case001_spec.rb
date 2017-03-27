require 'rails_helper'

RSpec.describe 'case001 data can be imported' do
  before :each do
    @result = `thor csv:seed --use case001`
  end
  it '1. creates 2 new records' do
    expect(User.count).to eq 2
  end
  it '2. first record is ok' do
    u1 = User.first
    expect(u1.name).to eq 'jiang chaofan'
    expect(u1.email).to eq 'jiangchaofan@gmail.com'
    expect(u1.mobile).to eq '123'
    expect(u1.authenticate('123')).to eql u1
  end
  it '3. second record is ok' do
    u2 = User.last
    expect(u2.name).to eq 'alice'
    expect(u2.email).to eq 'alice@notexists.atall'
    expect(u2.mobile).to eq '125'
    expect(u2.authenticate('125')).to eql u2
  end
end
