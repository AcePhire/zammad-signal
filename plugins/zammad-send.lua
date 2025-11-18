local http = require("http")
local json = require("json")

local send_url = "http://zammad-signal:8080/v2/send"
local payload = json.decode(pluginInputData.payload)

local sendPayload = {
	recipient = payload.ticket.customer.mobile,
	message = payload.article.body,
	number = pluginInputData.Params.number
}

local encodedSendPayload = json.encode(sendPayload)

response, error_message = http.request("POST", send_url, {
	timeout="30s",
	headers={
		Accept="*/*",
		["Content-Type"]="application/json"
	},
	body=encodedSendPayload
})
