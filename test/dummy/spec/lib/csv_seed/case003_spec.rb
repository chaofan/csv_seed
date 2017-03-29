require 'rails_helper'

RSpec.describe 'case003 foreign key can be linked to existing data' do
  before :each do
    # load users
    `csv_seed import --from case001`
    # load orders and link users
    `csv_seed import --from case003`
  end
  it '1. table counts is ok' do
    expect(User.count).to eq 2
    expect(Order.count).to eq 3
  end
  it "2. order\'s user is linked ok" do
    orders = Order.all
    users = User.all
    expect(orders[0].user).to eql users[0]
    expect(orders[1].user).to eql users[0]
    expect(orders[2].user).to eql users[1]
    expect(orders[2].user).to_not eql users[0]
  end
end
