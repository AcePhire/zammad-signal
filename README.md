<details>
    <summary>Click to Expand</summary>
# zammad-signal
Container-to-Container Integration

# Usage
## Create an environment file and add these variables
```
ZAMMAD_URL
ZAMMAD_USER
ZAMMAD_PASS
SIGNAL_URL
COUNTRY_CODE
SIGNAL_PHONE_NUMBER
GROUP
```

## Run docker-compose.yml
```
docker compose up -d
```
---
</details>
Signal API + Webhook Integratiopn

# Usage
## Add the configuration to zammad's `docker-compose.yml` file under `services`

```
zammad-signal:
    image: bbernhard/signal-cli-rest-api:latest
    environment:
      - MODE=active
      - ENABLE_PLUGINS=true
    volumes:
      - $HOME/.local/share/signal-api:/home/.local/share/signal-cli
      - "./plugins:/plugins"
```

## Add the authentication token to the environment variables for the Signal CLI container
```
ZAMMAD_AUTH_TOKEN={token}
```

## Copy the plugins to the `docker-compose.yml` directory

## Add Webhooks to Zammad
### Signal Send
```
Name: Signal Send
Endpoint: http://zammad-signal:8080/v1/plugins/zammad-send/%2B{country-code}{number}
```

### Signal Receive
```
Name: Signal Receive
Endpoint: http://zammad-signal:8080/v1/plugins/zammad-receive/%2B{country-code}{number}
Custom Payload: On
Custom Payload: empty
```

## Add Trigger for the Webhook to Send Message on Signal
```
Name: Send Signal Message
Conditions For Affected Objects:
- Ticket is created
- Send is Agent
Webhook: Signal Send
```
