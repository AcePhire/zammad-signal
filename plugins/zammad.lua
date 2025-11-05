local http = require("http")
local json = require("json")

GROUP = "ER"
local customEndpointPayload = json.decode(pluginInputData.payload)

local receive_url = "http://127.0.0.1:8080/v1/receive/" .. "%2B" .. string.sub(pluginInputData.Params.number, 2)
local zammad_url = "http://127.0.0.1:9000"
local authentication_token = "bAL2E6PDueSU146EnevBDmsdO--MFs2S63F-GXKnBRG5JLcF_1A2zKYK4cfQKGK0"

-- -------------------------------------------------------------

function createTicket(customer, message)
   data = {
       title = customer.mobile.." via Signal",
       state = "new",
       group = GROUP,
       customer_id = customer.id,
       article = {
           body = message,
       }
   }

   response, error_message = http.request("POST", zammad_url.."/api/v1/tickets", {
       headers={
           ["Authorization"]="Bearer " .. authentication_token,
           ["Content-Type"]="application/json",
           ["X-On-Behalf-Of"]=customer.id,
       },
       body = json.encode(data)
   })

   return response, error_message
end

-- -------------------------------------------------------------

function receiveReply(ticket, message)
   data = {
       ticket_id = ticket.id,
       body = message,
       type = "note",
       origin_by_id = ticket.customer_id
   }
 
   response, error_message = http.request("POST", zammad_url.."/api/v1/ticket_articles", {
       headers={
           ["Authorization"]="Bearer " .. authentication_token,
           ["Content-Type"]="application/json",
           ["X-On-Behalf-Of"]=ticket.customer,
       },
       body = json.encode(data)
   })

   return response, error_message
end

-- -------------------------------------------------------------

function createCustomer(customer_number)
   data = {
       mobile = customer_number,
       role = {"Customer"}
   }

   response, error_message = http.request("POST", zammad_url.."/api/v1/users", {
       headers={
           ["Authorization"]="Bearer " .. authentication_token,
           ["Content-Type"]="application/json",
       },
       body = json.encode(data)
   })

   return response, error_message
end

-- -------------------------------------------------------------

function getTicket(customer_number)
   query = "%28state.name:new%20OR%20state.name:open%29%20AND%20customer.mobile:"..customer_number
   response, error_message = http.request("GET", zammad_url.."/api/v1/tickets/search?query="..query, {
       headers={
           ["Authorization"]="Bearer " .. authentication_token,
           ["Content-Type"]="application/json",
       },
   })
   return response["body"]
end

-- -------------------------------------------------------------

function getCustomer(customer_number)
   query = customer_number
   response, error_message = http.request("GET", zammad_url.."/api/v1/users/search?query="..query, {
       headers={
           ["Authorization"]="Bearer " .. authentication_token,
           ["Content-Type"]="application/json",
       },
   })
   return response["body"]
end

-- -------------------------------------------------------------

function receiveMessageOnZammad(customer_number, message)
   ticket = json.decode(getTicket(customer_number))[1]
   if ticket == nil then
       customer = json.decode(getCustomer(customer_number))[1]

       if customer == nil then
           customer = json.decode(createCustomer(customer_number))[1]
       end

       createTicket(customer, message)
   else
       receiveReply(ticket, message)
   end
end

-- -------------------------------------------------------------

function receiveMessagesFromSignal()
    response, error_message = http.request("GET", receive_url, {
        timeout="30s",
        headers={
            ["Content-Type"]="application/json"
        },
    })

    local body = json.decode(response["body"])

    for _, v in pairs(body) do
        m = v.envelope.dataMessage
        customer_number = v.envelope.source
        print("Received a message from "..customer_number)

        if m ~= nil then
            receiveMessageOnZammad(customer_number, m.message)
        end
    end
end

while 1==1 do
    receiveMessagesFromSignal()
end
