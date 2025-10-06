require "zammad_api"
require 'uri'
require 'net/http'
require 'json'

ZAMMAD_URL = ENV["ZAMMAD_URL"]
USER = ENV["ZAMMAD_USER"]
PASS = ENV["ZAMMAD_PASS"]

SIGNAL_URL = ENV["SIGNAL_URL"]
COUNTRY_CODE = ENV["COUNTRY_CODE"]
SIGNAL_PHONE_NUMBER = ENV["SIGNAL_PHONE_NUMBER"]

GROUP = ENV["GROUP"]

$client = ZammadAPI::Client.new(
  url: ZAMMAD_URL,
  user: USER,
  password: PASS
)

# go through the articles of a customer's ticker and get the notes set by the agent then send it as a message through signal to the customer
def sendMessageFromZammad()
  customer_number = ""

  open_tickets = $client.ticket.search(query: '(state.name:new OR state.name:open) AND title:"via Signal"')
  open_tickets.each {|ticket|
    if ticket != nil
      customer_number = ticket.articles[0].from
      ticket.articles.each {|article|
        if article.from != customer_number and article.internal
          sendMessageToSignal(customer_number, article.body)

          article.internal = false
          article.save
        end
      }
    end
  }
end

def sendMessageToSignal(customer_number, message)
  body = {"message": "#{message}", "number": "+#{COUNTRY_CODE}#{SIGNAL_PHONE_NUMBER}", "recipients": [ "#{customer_number}" ]}

  uri = URI("#{SIGNAL_URL}/v2/send")
res = Net::HTTP.post(uri, body.to_json, {"Content-Type": "application/json"})
end

while true
  sendMessageFromZammad()
  sleep 1
end
