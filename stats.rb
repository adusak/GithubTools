require 'json'
require 'rest-client'
require 'pp'
require 'csv'

URL = 'https://api.github.com/repos/rhomobile/rhodes/stats/contributors'.freeze

response = RestClient.get URL
json = JSON.parse(response.to_str)
total = json.map { |e| e['total'] }.reduce(&:+)
puts "Total of commits: #{total}"

RHO_END = Time.new(2011, 10).to_i
MOTO_START = Time.new(2011, 10).to_i
MOTO_END = Time.new(2014, 4).to_i
ZEBRA_START = Time.new(2014, 4).to_i
ZEBRA_END = Time.new.to_i

result = []
charts = { rho: Hash.new(0), moto: Hash.new(0), zebra: Hash.new(0), total: Hash.new(0) }
json.each do |o|
  res_o = { name: o['author']['login'] }
  weeks = o['weeks']
  rho_weeks = weeks.select { |w_o| w_o['w'] < RHO_END }
  moto_weeks = weeks.select { |w_o| w_o['w'] >= MOTO_START && w_o['w'] <= MOTO_END }
  zebra_weeks = weeks.select { |w_o| w_o['w'] > ZEBRA_START }
  res_o[:rho_weeks_total] = rho_weeks.map { |w_o| w_o['c'] }.reduce(&:+)
  res_o[:moto_weeks_total] = moto_weeks.map { |w_o| w_o['c'] }.reduce(&:+)
  res_o[:zebra_weeks_total] = zebra_weeks.map { |w_o| w_o['c'] }.reduce(&:+)
  res_o[:total] = res_o[:rho_weeks_total] + res_o[:moto_weeks_total] + res_o[:zebra_weeks_total]
  res_o[:total_real] = weeks.map { |w_o| w_o['c'] }.reduce(&:+)

  weeks.each do |w|
    charts[:total][w['w']] = charts[:total][w['w']] + w['c']
  end
  rho_weeks.each do |w|
    charts[:rho][w['w']] = charts[:rho][w['w']] + w['c']
  end
  moto_weeks.each do |w|
    charts[:moto][w['w']] = charts[:moto][w['w']] + w['c']
  end
  zebra_weeks.each do |w|
    charts[:zebra][w['w']] = charts[:zebra][w['w']] + w['c']
  end

  result << res_o
end

sorted = result.sort_by { |e| e[:total] }.reverse.take(10)

File.open('contributors.csv', 'wb') do |file|
  sorted.each do |contr|
    file << "\n#{contr[:name]} & #{contr[:rho_weeks_total]} & #{contr[:moto_weeks_total]} & #{contr[:zebra_weeks_total]} & #{contr[:total_real]} \\\\"
  end
end

puts "\nALL THE CONTRIBUTORS\n"
pp sorted

def group_by_months(weeks)
  l_res = Hash.new(0)
  weeks.each do |d, c|
    time = Time.at(d)
    l_res[Time.new(time.year, time.month, 1)] = l_res[Time.new(time.year, time.month, 1)] + c
  end

  l_res
end

charts.each do |k, v|
  File.open("#{k}_chart.csv", 'wb') do |file|
    h = group_by_months(v)
    file << 'date,commits'
    h.each { |d, c| file << "\n#{d.strftime('%Y-%m-%d')},#{c}" }
  end
end
