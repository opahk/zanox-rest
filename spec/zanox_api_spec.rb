require 'yaml'
require 'zanox'
YAML::ENGINE.yamler = 'psych'
CONFIG = YAML.load_file('spec/zanox_data.yml')


describe "Zanox API" do

  it "establishes a connection to zanox api and gets basic report for a month in the past, checks it for sanety" do
    report = Zanox::Report.basic(Date.parse(CONFIG['basic']['fromdate']), Date.parse(CONFIG['basic']['todate']))
    report.total.should == CONFIG['basic']['total']
  end

  it "establishes a connection to zanox api and gets one hopefully correct dataset" do
    report = Zanox::Report.sales(Date.parse(CONFIG['sales']['date']))
    report.items.should == CONFIG['sales']['items']
    report.sale_items.sale_item.first.id.should == CONFIG['sales']['firstid']
    report.sale_items.sale_item.first.program.value.should == CONFIG['sales']['firstprogram']
    report.sale_items.sale_item.first.amount.to_s.should == CONFIG['sales']['firstamount'].to_s
  end

end
