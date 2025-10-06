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

# create a new ticket for the customer
def createTicket(title, customer, message)
  $client.perform_on_behalf_of(customer.login) do
    $client.ticket.create(
      title: title,
      state: "new",
      group: GROUP,
      priority: "2 normal",
      customer_id: customer.id,
      article: {
        content_type: "text/plain",
        body: message,
        type: "note"
      },
    )
  end
end

# add a new article for the customer
def receiveReply(ticket, message)
  $client.perform_on_behalf_of(ticket.customer) do
    ticket.article(
      body: message,
      type: "note"
    )
  end
end

def createCustomer(customer_number)
  return $client.user.create(
      mobile: customer_number,
      roles: ["Customer"]
  )
end

def getTicket(customer_number)
  return $client.ticket.search(query: '(state.name:new OR state.name:open) AND customer.mobile: \%s' % [customer_number])[0]
end

def getCustomer(customer_number)
    return $client.User.search(query: customer_number)[0]
end


# check if a new/open ticket exists and add an article to it, otherwise create a new one
def receiveMessageOnZammad(customer_number, message)
  ticket = getTicket(customer_number)

  if ticket==nil
    customer = getCustomer(customer_number)

    if customer==nil
      customer = createCustomer(customer_number)
    end

    createTicket("#{customer_number} via Signal", customer, message)
  else
    receiveReply(ticket, message)
  end
end


def receiveMessageFromSignal()
  uri = URI("#{SIGNAL_URL}/v1/receive/%2B#{COUNTRY_CODE}#{SIGNAL_PHONE_NUMBER}")
  res = Net::HTTP.get_response(uri)
  if res.is_a?(Net::HTTPSuccess)
    messages_json = JSON.parse(res.body)
    puts messages_json
    
    messages_json.each {|message_json|
      source_number = message_json["envelope"]["sourceNumber"]
      if source_number != "+#{COUNTRY_CODE}#{SIGNAL_PHONE_NUMBER}"
        message = message_json["envelope"]["dataMessage"]["message"]
        puts "#{source_number}: #{message}"
        receiveMessageOnZammad(source_number, message)
      end
    }
  end
end

while true
  receiveMessageFromSignal()
  sleep 1
end
