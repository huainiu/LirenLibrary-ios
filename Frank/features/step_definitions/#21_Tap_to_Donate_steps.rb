# coding: utf-8

Then /^I should be on the landing screen$/ do
	check_element_exists "view view:'UIRoundedRectButton' marked:'捐赠'"
	check_element_exists "view view:'UIRoundedRectButton' marked:'记录'"
end

When /^I tap 捐赠 button$/ do
	touch "view view:'UIRoundedRectButton' marked:'捐赠'"
	sleep(1)
end

Then /^I should be on the BookScanListViewController$/ do
	check_element_exists "view view:'UIRoundedRectButton' marked:'扫描'"
	check_element_exists "view view:'UITableView' marked:'Empty list'"
	check_element_exists "view view:'UINavigationItemView' marked:'立人捐书'"
end

When /^I tap 返回 button$/ do
	touch "view:'UINavigationItemButtonView' marked:'返回'"
	sleep(1)
end

When /^I tap 记录 button$/ do
	touch "view view:'UIRoundedRectButton' marked:'记录'"
	sleep(2)
end

Then /^I should be on the DonationListViewController$/ do

end